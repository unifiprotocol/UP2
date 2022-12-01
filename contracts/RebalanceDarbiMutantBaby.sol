// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/lib/contracts/libraries/Babylonian.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "./Libraries/UniswapHelper.sol";
import "./Interfaces/UnifiPair.sol";
import "./UPController.sol";
import "./UP.sol";
import "./Strategies/Strategy.sol";
import "./Helpers/Safe.sol";
import "./Darbi/UPMintDarbi.sol";

contract Rebalancer is AccessControl, Pausable, Safe {
  using SafeERC20 for IERC20;

  address public WETH;
  address public factory;

  IUnifiPair public liquidityPool;
  IUniswapV2Router02 public router;
  UP public UPToken;
  UPController public UP_CONTROLLER;
  UPMintDarbi public DARBI_MINTER;
  Strategy public strategy;

  uint256 private initRewardsPos = 0;
  IStrategy.Rewards[] public rewards;

  //DAO Parameters

  uint256 public allocationLP = 5; // Whole Number for Percent, i.e. 5 = 5%. If StrategyLockup = true, maximum amount is 100 - maximumAllocationLPWithLockup
  uint256 public callerReward = 10; // Whole Number for Percent, i.e. 5 = 5%. Represents the profit of rebalance that will go to the caller of the rebalance.
  uint256 public maximumAllocationLPWithLockup = 79; // Whole Number for Percent, i.e. 5 = 5%. MAKE UPGRADEABLE

  bool public strategyLockup; // if True, funds in Strategy are cannot be withdrawn immediately (such as staking on Harmony). If false, funds in Strategy are always available (such as AAVE on Polygon).

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Rebalancer: ONLY_ADMIN");
    _;
  }

  constructor(
    address _WETH,
    address _factory,
    address _Strategy,
    address _UPAddress,
    address _UPController,
    address _router,
    address _liquidityPool,
    address _fundsTarget
  ) Safe(_fundsTarget) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    WETH = _WETH;
    setUPController(_UPController);
    strategy = Strategy(payable(_Strategy));
    UPToken = UP(payable(_UPAddress));
    router = IUniswapV2Router02(_router);
    factory = _factory;
    liquidityPool = IUnifiPair(payable(_liquidityPool));
  }

  // Read Functions

  function getControllerBalance() internal view returns (uint256) {
    return UP_CONTROLLER.getNativeBalance();
  }

  function getLiquidityPoolBalance(uint256 reserves0, uint256 reserves1)
    public
    view
    returns (uint256, uint256)
  {
    uint256 lpBalance = liquidityPool.balanceOf(address(this));
    if (lpBalance == 0) {
      return (0, 0);
    }
    uint256 totalSupply = liquidityPool.totalSupply();
    uint256 amount0 = (lpBalance * reserves0) / totalSupply;
    uint256 amount1 = (lpBalance * reserves1) / totalSupply;
    return (amount0, amount1);
  }

  function moveMarketBuyAmount()
    public
    view
    returns (
      bool aToB,
      uint256 amountIn,
      uint256 reservesUP,
      uint256 reservesETH,
      uint256 upPrice
    )
  {
    (reservesUP, reservesETH) = UniswapHelper.getReserves(factory, address(UPToken), address(WETH));
    upPrice = UP_CONTROLLER.getVirtualPrice();

    (aToB, amountIn) = UniswapHelper.computeTradeToMoveMarket(
      1000000000000000000, // Ratio = 1:UPVirtualPrice
      upPrice,
      reservesUP,
      reservesETH
    );
    return (aToB, amountIn, reservesUP, reservesETH, upPrice);
  }

  function getRewardsLength() public view returns (uint256) {
    return rewards.length - initRewardsPos;
  }

  function getReward(uint256 position) public view returns (IStrategy.Rewards memory) {
    return rewards[initRewardsPos + position];
  }

  // Write Functions

  function rebalance() public whenNotPaused returns (uint256 proceeds, uint256 callerProfit) {
    if (address(strategy) != address(0)) {
      (proceeds, callerProfit) = _rebalanceWithStrategy();
    } else {
      (proceeds, callerProfit) = _rebalanceWithoutStrategy();
    }
  }

  // Internal Functions

  function _rebalanceWithStrategy() internal returns (uint256 proceeds, uint256 callerProfit) {
    // Store a snapshot of the rewards
    // Step 1
    IStrategy.Rewards memory strategyRewards = strategy.checkRewards();
    _saveReward(strategyRewards);

    // Withdraw the entire balance of the strategy
    // Step 2
    strategy.withdrawAll();
    (bool successUpcTransfer, ) = address(UP_CONTROLLER).call{value: address(this).balance}("");
    require(successUpcTransfer, "Rebalancer: FAIL_SENDING_BALANCE_TO_UPC");

    // Withdraw the entire balance of the LP
    // Step 3
    uint256 lpTokenBalance = IERC20(liquidityPool).balanceOf(address(this));
    liquidityPool.approve(address(router), lpTokenBalance);
    (uint256 amountToken, ) = router.removeLiquidityETH(
      address(UPToken),
      lpTokenBalance,
      0,
      0,
      address(this),
      block.timestamp + 150
    );
    UPController(UP_CONTROLLER).repay{value: address(this).balance}(amountToken);
    // UP Controller now has all available funds
    // Step 4 - Arbitrage
    _arbitrage();
    // Calculate Allocations
    // Step 5 - Refill LP
    uint256 totalETH = getControllerBalance(); //Accounts for locked strategies
    uint256 targetLpAmount = (totalETH * allocationLP) / 100;
    uint256 backedValue = UP_CONTROLLER.getVirtualPrice();
    uint256 upToAdd = targetLpAmount / backedValue;
    UP_CONTROLLER.borrowUP(upToAdd, address(this));
    // ERC20 Approval
    UPToken.approve(address(router), upToAdd);
    // Adds liquidity
    router.addLiquidityETH{value: targetLpAmount}(
      address(UPToken),
      upToAdd,
      0,
      0,
      address(this),
      block.timestamp + 150
    );
    // Step 6 - Refill Strategy
    uint256 controllerBalance = address(UP_CONTROLLER).balance;
    Strategy(strategy).deposit{value: controllerBalance}(controllerBalance);
    // Step 7 - Profit?
    (proceeds, callerProfit) = _refund();
    //EMIT EVENT HERE
    //Step 8 - Update UP Controller Variables
    uint256 nativeRemoved = Strategy(strategy).amountDeposited() + targetLpAmount;
    UPController(UP_CONTROLLER).setBorrowedAmounts(upToAdd, nativeRemoved);

    return (proceeds, callerProfit);
  }

  function _rebalanceWithoutStrategy() internal returns (uint256 proceeds, uint256 callerProfit) {
    // Withdraw the entire balance of the LP
    // Step 1
    uint256 lpTokenBalance = IERC20(liquidityPool).balanceOf(address(this));
    liquidityPool.approve(address(router), lpTokenBalance);
    (uint256 amountToken, ) = router.removeLiquidityETH(
      address(UPToken),
      lpTokenBalance,
      0,
      0,
      address(this),
      block.timestamp + 150
    );
    UPController(UP_CONTROLLER).repay{value: address(this).balance}(amountToken);
    // UP Controller now has all available funds
    // Step 2 - Arbitrage
    _arbitrage();
    // Step 3 - Refill LP
    uint256 targetLpAmount = getControllerBalance();
    uint256 backedValue = UP_CONTROLLER.getVirtualPrice();
    uint256 upToAdd = targetLpAmount / backedValue;
    UP_CONTROLLER.borrowUP(upToAdd, address(this));
    UPToken.approve(address(router), upToAdd);
    router.addLiquidityETH{value: targetLpAmount}(
      address(UPToken),
      upToAdd,
      0,
      0,
      address(this),
      block.timestamp + 150
    );
    // Step 4 - Profit?
    (proceeds, callerProfit) = _refund();
    //EMIT EVENT HERE
    //Step 5 - Update UP Controller Variables
    uint256 nativeRemoved = address(UP_CONTROLLER).balance + targetLpAmount;
    UPController(UP_CONTROLLER).setBorrowedAmounts(upToAdd, nativeRemoved);
    return (proceeds, callerProfit);
  }

  function _arbitrage() internal {
    (
      bool aToB, // The direction of the arbitrage. If true, Darbi is buying UP from the LP. If false, Darbi is selling UP to the LP.
      uint256 amountIn, //if buying UP, number returned is in native value. If selling UP, number returned in UP value.
      uint256 reserves0,
      uint256 reserves1,
      uint256 backedValue // The current backed Value of
    ) = moveMarketBuyAmount();

    // aToB == true == Buys UP
    // aToB == fals == Sells UP
    uint256 fundsAvailable = (address(UP_CONTROLLER).balance / 3);
    // Checks amount Native Tokens available for Darbi, either from the Controller or the Strategy
    uint256 tradeSize;
    // Declaring variable in advance. Represents the amount of token input per transaction, determined based on the actual trade size, or the maximum size available - whichever is lower.
    // For example, if buying UP, and if 100 BNB is required to move the market so that backed value = market value, and 120 BNB is available - then the tradeSize is 100 BNB.
    // However, if buying UP, and if 100 BNB is requred to move the market so that backed value = market value, and 50 BNB is available - then the tradeSize is 50 BNB.
    uint256 actualAmountIn;
    // Declaring variable in advance. Represents the total amount of native token input required to move the market so backed value = market value.
    // If buying UP, this value will be the same as the amountIn. If selling UP, this value will be the amountIn * backedValue.

    // If Buying UP
    if (!aToB) {
      actualAmountIn == amountIn;
      while (actualAmountIn > 0) {
        // Sets a loop so that if the amount of native tokens required to move the market so that MV = BV is larger than the funds available, the transaction will repeat until the prices match.
        if (actualAmountIn > fundsAvailable) {
          // Checks if amount of native required to move the market is greater than funds available in the strategy / controller
          tradeSize = fundsAvailable;
          // Sets tradesize to amount of funds Darbi has access to.
          actualAmountIn -= tradeSize;
          // Reduces the amount required to complete market movement.
        } else {
          // If there is enough funds available to move the market so that MV = BV, the tradeSize will equal the amount required, and will not repeat.
          tradeSize = actualAmountIn;
          actualAmountIn == 0;
        }

        uint256 expectedReturn = UniswapHelper.getAmountOut(tradeSize, reserves1, reserves0); // Amount of UP expected from Buy
        uint256 expectedNativeReturn = (expectedReturn * backedValue) / 1e18; //Amount of Native Tokens Expected to Receive from Redeem
        uint256 upControllerBalance = (address(UP_CONTROLLER).balance / 3) * 2;

        if (upControllerBalance < expectedNativeReturn) {
          // If upControllerBalance below amountOut of UP required, then triggers rebalance.
          // Checks if there is enough native tokens in the UP Controller to redeem the UP purchased
          uint256 upOutput = (upControllerBalance * 1e18) / backedValue;
          // Gets the maximum amount of UP that can be redeemed.
          tradeSize = UniswapHelper.getAmountIn(upOutput, reserves1, reserves0);
          // Calculates the amount of native tokens required to purchase the maxiumum of UP that can be redeemed.
          actualAmountIn += (tradeSize - upOutput);
          // Adjusts the total amount required to move market to account for the smaller trade size. Note this transaction will still end with MV=BV, just requires more loops.
        }

        UPController(UP_CONTROLLER).borrowNative(tradeSize, address(this));
        _arbitrageBuy(tradeSize);
        UPController(UP_CONTROLLER).repay{value: tradeSize}(0);
      }
    } else {
      // If Selling Up
      while (
        amountIn > 100 //As there may be a slight rounding in UP sales, a small amount of UP token dust may occur. This allows for dust + rounding of 100 gwei of UP
      ) {
        actualAmountIn = amountIn *= backedValue;
        // Calculates the amount of native tokens required to mint the amount of UP to sell into the LP.
        if (actualAmountIn > fundsAvailable) {
          // Checks if amount of native required to move the market is greater than funds available in the strategy / controller
          tradeSize = fundsAvailable;
          // Sets tradesize to amount of funds Darbi has access to.
          actualAmountIn -= tradeSize;
          // Reduces the amount required to complete market movement.
        } else {
          // If there is enough funds available to move the market so that MV = BV, the tradeSize will equal the amount required, and will not repeat.
          tradeSize = actualAmountIn;
          actualAmountIn == 0;
        }
        UPController(UP_CONTROLLER).borrowNative(tradeSize, address(this));
        uint256 upSold = _arbitrageSell(tradeSize);
        amountIn -= upSold;
        // Takes the amount of UP minted and sold in this transaction, and subtracts it from the total amount of UP required to move the market so that MV = BV
        UPController(UP_CONTROLLER).repay{value: tradeSize}(0);
      }
    }
    // Returns the total profit in native tokens expected by the transaction.
    // If this arbitrage is triggered by a public caller, returns the amount of 'reward' the caller will receive. If triggered by the rebalancer, returns 0.
  }

  function _arbitrageBuy(uint256 amountIn) internal {
    address[] memory path = new address[](2);
    path[0] = WETH;
    path[1] = address(UPToken);

    uint256[] memory amounts = router.swapExactETHForTokens{value: amountIn}(
      0,
      path,
      address(this),
      block.timestamp + 150
    );

    UPToken.approve(address(UP_CONTROLLER), amounts[1]);
    UP_CONTROLLER.redeem(amounts[1]);
  }

  function _arbitrageSell(uint256 tradeSize) internal returns (uint256 up2Balance) {
    // If selling UP
    DARBI_MINTER.mintUP{value: tradeSize}();

    address[] memory path = new address[](2);
    path[0] = address(UPToken);
    path[1] = WETH;

    up2Balance = UPToken.balanceOf(address(this));
    UPToken.approve(address(router), up2Balance);
    router.swapExactTokensForETH(up2Balance, 0, path, address(this), block.timestamp + 150);
  }

  function _refund() internal returns (uint256 proceeds, uint256 callerBonus) {
    proceeds = address(this).balance;
    // Any leftover funds in the contract is profit. Yay!
    callerBonus = ((proceeds * callerReward) / 100);
    (bool success2, ) = (msg.sender).call{value: callerBonus}("");
    require(success2, "Darbi: FAIL_SENDING_PROFITS_TO_CALLER");
    UPController(UP_CONTROLLER).repay{value: address(this).balance}(0);
    return (proceeds, callerBonus);
  }

  function _saveReward(IStrategy.Rewards memory reward) internal {
    if (getRewardsLength() == 10) {
      delete rewards[initRewardsPos];
      initRewardsPos += 1;
    }
    rewards.push(reward);
  }

  // Setter Functions

  function setDarbiMinter(address newAddress) public onlyAdmin {
    require(newAddress != address(0));
    DARBI_MINTER = UPMintDarbi(payable(newAddress));
  }

  function setStrategy(address newAddress) public onlyAdmin {
    // Can be 0x00
    strategy = Strategy(payable(newAddress));
  }

  function setUPController(address newAddress) public onlyAdmin {
    require(newAddress != address(0));
    UP_CONTROLLER = UPController(payable(newAddress));
  }

  function setStrategyLockup(bool isTrue) public onlyAdmin {
    strategyLockup = isTrue;
  }

  function setCallerReward(uint256 percentCallerReward) public onlyAdmin {
    require(percentCallerReward <= 100);
    callerReward = percentCallerReward;
  }

  function setAllocationLP(uint256 _allocationLP) public onlyAdmin returns (bool) {
    if (strategyLockup == true) {
      require(
        _allocationLP < maximumAllocationLPWithLockup,
        "Rebalancer: The strategy lockup requires an allocation below the maximum allocation LP variable"
      );
    }
    allocationLP = _allocationLP;
    return true;
  }

  function setmaximumAllocationLPWithLockup(uint256 _maximumAllocationLPWithLockup)
    public
    onlyAdmin
    returns (bool)
  {
    require(
      _maximumAllocationLPWithLockup <= 100,
      "Rebalancer: Maximum Allocation LP cannot be above 100%"
    );
    maximumAllocationLPWithLockup = _maximumAllocationLPWithLockup;
    return true;
  }

  // Admin Functions

  /// @notice Permissioned function to withdraw any native coins accidentally deposited to the Public Mint contract.
  function withdrawFunds() public onlyAdmin returns (bool) {
    return _withdrawFunds();
  }

  /// @notice Permissioned function to withdraw any tokens accidentally deposited to the Public Mint contract.
  function withdrawFundsERC20(address tokenAddress) public onlyAdmin returns (bool) {
    return _withdrawFundsERC20(tokenAddress);
  }

  /// @notice Permissioned function to pause UPToken Controller
  function pause() public onlyAdmin {
    _pause();
  }

  /// @notice Permissioned function to unpause UPToken Controller
  function unpause() public onlyAdmin {
    _unpause();
  }

  // Fallback Function
  receive() external payable {}
}
