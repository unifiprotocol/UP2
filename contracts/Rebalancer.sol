// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "./Libraries/UniswapHelper.sol";
import "./Interfaces/UnifiPair.sol";
import "./UPController.sol";
import "./UP.sol";
import "./Strategies/Strategy.sol";
import "./Helpers/Safe.sol";

contract Rebalancer is AccessControl, Pausable, Safe {
  using SafeERC20 for IERC20;

  address public WETH;
  address public factory;
  uint256 public tradingFeeOfAMM = 25; //Calculated in basis points. i.e. 5 = 0.05%
  uint256 public maximumAllocationLPWithLockup = 79; // Whole Number for Percent, i.e. 5 = 5%.
  bool public strategyLockup; // if True, funds in Strategy are cannot be withdrawn immediately (such as staking on Harmony). If false, funds in Strategy are always available (such as AAVE on Polygon).

  IUnifiPair public liquidityPool;
  IUniswapV2Router02 public router;
  UP public UPToken;
  UPController public UP_CONTROLLER;
  Strategy public strategy;
  uint256 private initRewardsPos = 0;
  Strategy.Rewards[] public rewards;

  //DAO Parameters

  uint256 public allocationLP = 100; // Whole Number for Percent, i.e. 5 = 5%. If StrategyLockup = true, maximum amount is 100 - maximumAllocationLPWithLockup
  //If there is no strategy, the allocationLP will default to 100%
  uint256 public callerReward = 50; // Basis Points for Percent, i.e. 5 = 0.05%. Represents the profit of rebalance that will go to the caller of the rebalance.
  uint256 public allocationRedeem = 0; //Whole Number for Percent, i.e 5 = 5%. If a balance is required for redeeming UP, simply set this variable to a percent.
  uint256 public minimumRedeem = 50000000000000000; // The minimum amount of wei that can be redeemed. This is a check if the controller is near empty, and would make buying UP wasteful. Default is 0.05 ETH.
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
    UP_CONTROLLER = UPController(payable(_UPController));
    strategy = Strategy(payable(_Strategy));
    UPToken = UP(payable(_UPAddress));
    router = IUniswapV2Router02(_router);
    factory = _factory;
    liquidityPool = IUnifiPair(payable(_liquidityPool));
  }

  // Read Functions

  /// @notice This function is used to check the current allocation of the LP
  /// @return up The amount of UP in the LP
  /// @return native The amount of native tokens in the LP
  function getLiquidityPoolBalance() public view returns (uint256 up, uint256 native) {
    (uint256 reservesUP, uint256 reservesETH) = UniswapHelper.getReserves(
      factory,
      address(UPToken),
      address(WETH)
    );
    uint256 lpBalance = liquidityPool.balanceOf(address(this));
    uint256 totalSupply = liquidityPool.totalSupply();
    uint256 upInLP = (lpBalance * reservesUP) / totalSupply;
    uint256 nativeInLP = (lpBalance * reservesETH) / totalSupply;
    return (upInLP, nativeInLP);
  }

  /// @notice Calculates the amount required to move the market to the desired ratio
  /// @return aToB True if the trade is from A to B (buying UP in this case), False if the trade is from B to A (selling UP in this case)
  /// @return amountIn The amount of ETH or native tokens required to move the market to the desired ratio
  /// @return reservesUP The amount of UP in the LP
  /// @return reservesETH The amount of ETH or native tokens in the LP
  /// @return upPrice The current price of UP
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
      reservesETH,
      tradingFeeOfAMM
    );
    return (aToB, amountIn, reservesUP, reservesETH, upPrice);
  }

  /// @notice Gets the amount of data points in the rewards array
  /// @return The length of the rewards array
  function getRewardsLength() public view returns (uint256) {
    return rewards.length - initRewardsPos;
  }

  /// @notice Gets the data point at a specific position in the rewards array
  /// @param position The position in the array to get the data point from
  /// @return The data point at the specified position
  function getReward(uint256 position) public view returns (Strategy.Rewards memory) {
    return rewards[initRewardsPos + position];
  }

  // Write Functions

  /// @notice Publically callable rebalance function to compound rewards from the strategy, arbitrage the LP, and re-allocate assets to LP, Strategy, and Controller
  /// @return proceeds The amount of profit generated from the rebalance given to the controller
  /// @return callerProfit The amount of profit generated from the rebalance given to the caller
  function rebalance() external whenNotPaused returns (uint256 proceeds, uint256 callerProfit) {
    // Step 1
    // Store a snapshot of the rewards earned by the strategy
    if (address(strategy) != address(0)) {
      Strategy.Rewards memory strategyRewards = strategy.checkRewards();
      _saveReward(strategyRewards);

      // Step 2
      // Withdraw the entire balance of the strategy. If strategyLockup = true, some funds are not immediately available.

      if (strategyLockup == true) {
        strategy.gather();
        uint256 amountToWithdraw = address(strategy).balance;
        strategy.withdraw(amountToWithdraw);
        address(UP_CONTROLLER).call{value: address(this).balance};
      } else {
        strategy.withdrawAll();
        address(UP_CONTROLLER).call{value: address(this).balance};
      }
    }

    // Step 3
    // Withdraw the entire balance of the LP.

    uint256 lpTokenBalance = IERC20(liquidityPool).balanceOf(address(this));
    if (lpTokenBalance != 0) {
      liquidityPool.approve(address(router), lpTokenBalance);
      router.removeLiquidityETH(
        address(UPToken),
        lpTokenBalance,
        0,
        0,
        address(this),
        block.timestamp + 150
      );
      uint256 amountToken = UPToken.balanceOf(address(this));
      UPToken.approve(address(UP_CONTROLLER), amountToken);
      uint256 amountUPborrowed = UPController(UP_CONTROLLER).upBorrowed();
      if (amountToken <= amountUPborrowed) {
        UPController(UP_CONTROLLER).repay{value: address(this).balance}(amountToken);
      } else {
        uint256 upToJustBurn = amountToken - amountUPborrowed;
        UPController(UP_CONTROLLER).repay{value: address(this).balance}(amountUPborrowed);
        UPToken.justBurn(upToJustBurn);
      }
    } // UP Controller now has all available funds
    _setBorrowedBalances();

    // Step 4
    // Arbitrage market value to backed value, if needed. This is done by buying UP with ETH, or selling UP for ETH.

    _arbitrage();
    (proceeds, callerProfit) = _refund();
    _setBorrowedBalances();

    // Step 5
    // Refill LP with allocated amount of funds. This is done by borrowing UP and ETH from the UP Controller, and adding liquidity to the LP.

    uint256 totalETH = UP_CONTROLLER.getNativeBalance(); //Accounts for locked strategies
    uint256 targetLpAmount = (totalETH * allocationLP) / 100;
    uint256 backedValue = UP_CONTROLLER.getVirtualPrice();
    uint256 upToAdd = ((targetLpAmount * 1e18) / backedValue);
    UP_CONTROLLER.borrowUP(upToAdd, address(this));
    UP_CONTROLLER.borrowNative(targetLpAmount, address(this));
    UPToken.approve(address(router), upToAdd);
    router.addLiquidityETH{value: targetLpAmount}(
      address(UPToken),
      upToAdd,
      0,
      0,
      address(this),
      block.timestamp + 150
    );

    // Step 6
    // Refill Strategy with allocated amount of funds. This is done by borrowing ETH from the UP Controller, and depositing into the strategy.

    if (address(strategy) != address(0)) {
      uint256 strategySend = address(UP_CONTROLLER).balance;
      if (allocationRedeem > 0) {
        uint256 strategyAllocation = 100 - allocationRedeem;
        uint256 strategyAmount = (strategySend * strategyAllocation) / 100;
        strategySend = strategyAmount;
      }
      UP_CONTROLLER.borrowNative(strategySend, address(this));
      strategy.deposit{value: strategySend}(strategySend);
    }

    // Step 7
    // Update UP Controller Variables based on amount of funds sent to LP and Strategy.

    if (address(strategy) != address(0)) {
      targetLpAmount += strategy.amountDeposited();
    }
    UP_CONTROLLER.setBorrowedAmounts(upToAdd, targetLpAmount);
    return (proceeds, callerProfit);
  }

  // Internal Functions

  ///@notice Arbitrage market value to backed value, if needed. This is done by buying UP with ETH, or selling UP for ETH.
  function _arbitrage() internal {
    (
      bool aToB, // The direction of the arbitrage. If true, Darbi is buying UP from the LP. If false, Darbi is selling UP to the LP.
      uint256 amountIn, //if buying UP, number returned is in native value. If selling UP, number returned in UP value.
      uint256 reserves0,
      uint256 reserves1,
      uint256 backedValue // The current backed Value of
    ) = moveMarketBuyAmount();

    // aToB == true == Buys UP
    // aToB == false == Sells UP
    uint256 tradeSize;
    // Declaring variable in advance. Represents the amount of token input per transaction, determined based on the actual trade size, or the maximum size available - whichever is lower.
    // For example, if buying UP, let's say 100 BNB is required to move the market so that backed value = market value, and 110 BNB is available - then the tradeSize is 100 BNB.
    // However, if 100 BNB is requred to move the market so that backed value = market value, and 50 BNB is available - then the tradeSize is 50 BNB.

    // If Buying UP
    if (!aToB) {
      uint256 actualAmountIn = amountIn;
      uint256 upControllerBalance = (address(UP_CONTROLLER).balance / 3) * 2;
      uint256 fundsAvailable = (address(UP_CONTROLLER).balance / 3);
      while (actualAmountIn > 0 && upControllerBalance >= minimumRedeem) {
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

        uint256 expectedReturn = UniswapHelper.getAmountOut(
          tradeSize,
          reserves1,
          reserves0,
          tradingFeeOfAMM
        ); // Amount of UP expected from Buy
        uint256 expectedNativeReturn = (expectedReturn * backedValue) / 1e18; //Amount of Native Tokens Expected to Receive from Redeem
        if (upControllerBalance < expectedNativeReturn) {
          // Note If upControllerBalance below amountOut of UP required, then triggers rebalance.
          // Note Checks if there is enough native tokens in the UP Controller to redeem the UP purchased
          uint256 upOutput = (upControllerBalance * 1e18) / backedValue;
          // Note Gets the maximum amount of UP that can be redeemed.
          tradeSize = UniswapHelper.getAmountIn(upOutput, reserves1, reserves0, tradingFeeOfAMM);
          // Note Calculates the amount of native tokens required to purchase the maxiumum of UP that can be redeemed.
          actualAmountIn -= tradeSize;
          // Note Adjusts the total amount required to move market to account for the smaller trade size. This transaction will still end with MV=BV, just requires more loops.
        }

        _arbitrageBuy(tradeSize, expectedReturn);
        UP_CONTROLLER.repay(0){value: tradeSize};
        upControllerBalance = (address(UP_CONTROLLER).balance / 3) * 2;
        fundsAvailable = (address(UP_CONTROLLER).balance / 3);
      }
    } else {
      uint256 backedValueOfUpSold = amountIn * backedValue;
      _arbitrageSell(amountIn, backedValueOfUpSold);
      (bool success, ) = address(UP_CONTROLLER).call{value: backedValueOfUpSold}("");
      require(success, "Rebalancer: FAIL_SENDING_UP_BACKING_TO_CONTROLLER");
      // Note Borrowed UP value is zeroed after transaction by _setBorrowedBalances, so no need to repay.
    }
  }

  /// @notice Buys UP from the LP and redeems for native tokens from the UP Controller
  /// @param amountIn The amount of native tokens to be used to buy UP
  /// @param expectedReturn The amount of native tokens expected to received from redeeming UP
  function _arbitrageBuy(uint256 amountIn, uint256 expectedReturn) internal {
    UP_CONTROLLER.borrowNative(tradeSize, address(this));
    address[] memory path = new address[](2);
    path[0] = WETH;
    path[1] = address(UPToken);

    uint256[] memory amounts = router.swapExactETHForTokens{value: amountIn}(
      expectedReturn,
      path,
      address(this),
      block.timestamp + 150
    );

    UPToken.approve(address(UP_CONTROLLER), amounts[1]);
    _redeem(amounts[1]);
  }

  /// @notice Sells UP for native tokens and sends to the UP Controller
  /// @param upToMint The amount of UP to be minted and sold for native tokens
  /// @param backedValueOfUpSold The backed value in native tokens of the UP being sold
  function _arbitrageSell(uint256 upToMint, uint256 backedValueOfUpSold) internal {
    UP_CONTROLLER.borrowUP(upToMint, address(this));

    address[] memory path = new address[](2);
    path[0] = address(UPToken);
    path[1] = WETH;

    UPToken.approve(address(router), upToMint);
    router.swapExactTokensForETH(
      upToMint,
      backedValueOfUpSold,
      path,
      address(this),
      block.timestamp + 150
    );
  }

  /// @notice Sets the Borrowed Balances in the UP Controller before an arbitrage call during rebalance
  function _setBorrowedBalances() internal whenNotPaused {
    if (strategyLockup == true) {
      UP_CONTROLLER.setBorrowedAmounts(
        0,
        (address(UP_CONTROLLER).balance - strategy.amountDeposited())
      );
    } else {
      UP_CONTROLLER.setBorrowedAmounts(0, 0);
    }
  }

  /// @notice Mints UP at the mint rate, deposits the native tokens to the UP Controller, Sends UP to the Msg.sender
  /// @param upToMint The amount of UP to mint
  function _mintUP(uint256 upToMint) internal whenNotPaused {
    UPToken.mint(address(this), upToMint);
  }

  /// @notice Allows Rebalancer to redeem the native tokens backing UP
  /// @param upAmount The amount of UP to redeem
  function _redeem(uint256 upAmount) internal whenNotPaused {
    UPToken.approve(address(UP_CONTROLLER), upAmount);
    uint256 prevBalance = address(this).balance;
    UP_CONTROLLER.redeem(upAmount);
    uint256 postBalance = address(this).balance;
    require(postBalance > prevBalance, "Rebalancer: FAIL_TO_REDEEM_ON_ARBITRAGE_SELL");
  }

  /// @notice Distributes profits to the caller and the UP Controller
  /// @return proceeds The amount of native tokens distributed to the UP Controller
  /// @return callerBonus The amount of native tokens distributed to the caller
  function _refund() internal returns (uint256 proceeds, uint256 callerBonus) {
    proceeds = address(this).balance;
    if (proceeds < 10000) {
      return (0, 0);
    }
    callerBonus = ((proceeds * callerReward) / 10000);
    (bool success1, ) = (msg.sender).call{value: callerBonus}("");
    require(success1, "Rebalancer: FAIL_SENDING_PROFITS_TO_CALLER");
    (bool success2, ) = (address(UP_CONTROLLER)).call{value: address(this).balance}("");
    require(success2, "Rebalancer: FAIL_SENDING_PROFITS_TO_CONTROLLER");
    return (proceeds, callerBonus);
  }

  /// @notice Saves the rewards earned by the strategy in the rewards array
  /// @param reward The reward earned by the strategy
  function _saveReward(Strategy.Rewards memory reward) internal {
    if (getRewardsLength() == 10) {
      delete rewards[initRewardsPos];
      initRewardsPos += 1;
    }
    rewards.push(reward);
  }

  // Setter Functions

  /// @notice Sets the address of the Strategy contract
  /// @param newAddress The address of the Strategy contract
  function setStrategy(address newAddress) external onlyAdmin {
    // Can be 0x00
    strategy = Strategy(payable(newAddress));
  }

  /// @notice Sets the address of the UP Controller contract
  /// @param newAddress The address of the UP Controller contract
  function setUPController(address newAddress) external onlyAdmin {
    require(newAddress != address(0));
    UP_CONTROLLER = UPController(payable(newAddress));
  }

  /// @notice Sets true/false if the Strategy contract involves a lockup period
  /// @param isTrue True if the Strategy contract involves a lockup period
  function setStrategyLockup(bool isTrue) external onlyAdmin {
    strategyLockup = isTrue;
  }

  /// @notice Sets the percentage of profits that are sent to the caller who called the rebalance function. Value is in basis points i.e. 1000 = 10%
  /// @param percentCallerReward The percentage of profits in basis points that are sent to the caller who called the rebalance function
  function setCallerReward(uint256 percentCallerReward) external onlyAdmin {
    require(percentCallerReward <= 10000);
    callerReward = percentCallerReward;
  }

  /// @notice Sets the percentage in whole numbers of native tokens that will be deposited to the liquidity pool
  /// @param _allocationLP The percentage in whole numbers of native tokens that will be deposited to the liquidity pool
  function setAllocationLP(uint256 _allocationLP) external onlyAdmin {
    if (strategyLockup == true) {
      require(_allocationLP < maximumAllocationLPWithLockup);
    }
    allocationLP = _allocationLP;
  }

  /// @notice Sets the percentage in whole numbers of backed tokens that will held in the UP Controller
  /// @param _allocationRedeem The percentage in whole numbers of backed tokens that will held in the UP Controller
  function setAllocationRedeem(uint256 _allocationRedeem) external onlyAdmin {
    require(_allocationRedeem <= 100);
    allocationRedeem = _allocationRedeem;
  }

  /// @notice Sets the maximum percentage in whole numbers that can be allocated to the LP when the strategy contains a lockup period.
  /// @param _maximumAllocationLPWithLockup The maximum percentage in whole numbers that can be allocated to the LP when the strategy contains a lockup period.
  function setmaximumAllocationLPWithLockup(uint256 _maximumAllocationLPWithLockup)
    external
    onlyAdmin
  {
    require(_maximumAllocationLPWithLockup <= 100);
    maximumAllocationLPWithLockup = _maximumAllocationLPWithLockup;
  }

  /// @notice Sets the minimum amount of native tokens in wei in the UP Controller for an arbitrage buy to occur. If below, the loop will end.
  /// @param _minimumRedeem The minimum amount of native tokens in wei in the UP Controller for an arbitrage buy to occur. If below, the loop will end.
  function setMinimumRedeem(uint256 _minimumRedeem) external onlyAdmin {
    minimumRedeem = _minimumRedeem;
  }

  // Admin Functions

  /// @notice Permissioned function to withdraw any native coins accidentally deposited to the Public Mint contract.
  function withdrawFunds() external onlyAdmin returns (bool) {
    return _withdrawFunds();
  }

  /// @notice Permissioned function to withdraw any tokens accidentally deposited to the Public Mint contract. Can be used to withdraw LP tokens.
  /// @param tokenAddress The address of the token to withdraw
  function withdrawFundsERC20(address tokenAddress) external onlyAdmin returns (bool) {
    return _withdrawFundsERC20(tokenAddress);
  }

  // Fallback Function
  receive() external payable {}
}
