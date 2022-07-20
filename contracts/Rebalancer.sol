// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./Libraries/UniswapHelper.sol";
import "./Interfaces/UnifiPair.sol";
import "./UPController.sol";
import "./UP.sol";
import "./Strategies/IStrategy.sol";
import "./Helpers/Safe.sol";
import "./Darbi/Darbi.sol";

contract Rebalancer is AccessControl, Pausable, Safe {
  bytes32 public constant REBALANCE_ROLE = keccak256("REBALANCE_ROLE");

  address public WETH = address(0);
  IStrategy public strategy;
  address public unifiFactory = address(0);
  IUnifiPair public liquidityPool;
  Darbi public darbi;
  UP public UPToken;
  UPController public UP_CONTROLLER;
  uint256 public allocationLP = 5; //Whole Number for Percent, i.e. 5 = 5%
  uint256 public allocationRedeem = 5; //Whole Number for Percent, i.e. 5 = 5%
  uint256 public slippageTolerance = 10; //Percent with 2 Percision, i.e. 10 = 0.1%

  IUniswapV2Router02 public unifiRouter;
  IStrategy.Rewards[] public rewards;

  modifier onlyRebalance() {
    require(hasRole(REBALANCE_ROLE, msg.sender), "ONLY_REBALANCE");
    _;
  }

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ONLY_ADMIN");
    _;
  }

  constructor(
    address _WETH,
    address _UPAddress,
    address _UPController,
    address _Strategy,
    address _unifiRouter,
    address _unifiFactory,
    address _liquidityPool,
    address _darbi
  ) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    WETH = _WETH;
    setUPController(_UPController);
    strategy = IStrategy(_Strategy);
    UPToken = UP(payable(_UPAddress));
    unifiRouter = IUniswapV2Router02(_unifiRouter);
    unifiFactory = _unifiFactory;
    liquidityPool = IUnifiPair(payable(_liquidityPool));
    darbi = Darbi(payable(_darbi));
  }

  receive() external payable {}

  function claimAndBurn() internal {
    liquidityPool.claimUP(address(this));
    UPToken.justBurn(UPToken.balanceOf(address(this)));
  }

  function getupcBalance() internal view returns (uint256) {
    return UP_CONTROLLER.getNativeBalance();
  }

  function rebalance() public whenNotPaused onlyRebalance {
    if (address(strategy) != address(0)) {
      _rebalanceWithStrategy();
    } else {
      _rebalanceWithoutStrategy();
    }
  }

  function _rebalanceWithStrategy() public whenNotPaused onlyRebalance {
    // Step 1
    claimAndBurn();

    // Store a snapshot of the rewards
    IStrategy.Rewards memory strategyRewards = strategy.checkRewards();
    saveReward(strategyRewards);

    // Gather the generated rewards by the strategy and send them to the UPController
    // Step 2
    strategy.gather();
    (bool successUpcTransfer, ) = address(UP_CONTROLLER).call{value: strategyRewards.rewardsAmount}(
      ""
    );
    require(successUpcTransfer, "FAIL_SENDING_REWARDS_TO_UPC");
    // UPController balances after get rewards

    // Force Arbitrage
    // Step 3
    darbi.forceArbitrage();

    (uint256 reserves0, uint256 reserves1) = UniswapHelper.getReserves(
      unifiFactory,
      address(UPToken),
      WETH
    );
    (uint256 amountLpUP, uint256 amountLpETH) = getLiquidityPoolBalance(reserves0, reserves1);
    uint256 totalETH = amountLpETH + getupcBalance() + strategyRewards.depositedAmount;

    //Take money from the strategy - 5% of the total of the strategy
    // Step 4
    uint256 targetRedeemAmount = (totalETH * allocationRedeem) / 100;
    //Step 4.1
    if (address(UP_CONTROLLER).balance > targetRedeemAmount) {
      // If UP Controller balance is greater than 5%, the rebalancer withdraws from the UP Controller to deposit into the strategy
      uint256 amountToWithdraw = address(UP_CONTROLLER).balance - targetRedeemAmount;
      UP_CONTROLLER.borrowNative(amountToWithdraw, address(this));
      strategy.deposit{value: amountToWithdraw}(amountToWithdraw);
      //Step 4.2
    } else if (address(UP_CONTROLLER).balance < targetRedeemAmount) {
      // If UP Controller balance is less than 5%, the rebalancer withdraws from the strategy to deposit into the UP Controller
      uint256 amountToDeposit = targetRedeemAmount - address(UP_CONTROLLER).balance;
      strategy.withdraw(amountToDeposit);
      UP_CONTROLLER.repay{value: amountToDeposit}(0);
    }

    // REBALANCE LP
    // Step 5
    uint256 lpBalance = liquidityPool.balanceOf(address(this));
    uint256 backedValue = UP_CONTROLLER.getVirtualPrice();
    uint256 marketValue = (reserves0 * 1e18) / reserves1;
    // Step 5.1
    if (
      backedValue > (marketValue * (1 + (slippageTolerance / 10000))) ||
      backedValue < (marketValue * (1 - (slippageTolerance / 10000)))
    ) {
      return;
    }

    uint256 LPtargetAmount = (totalETH * allocationLP) / 100;
    // Step 6
    // Step 6.1
    if (amountLpETH > LPtargetAmount) {
      // withdraw the amount of LP so that getupcBalance() = ETHtoTake, send native tokens to Strategy, 'repay' / burn the synthetic UP withdrawn
      uint256 ETHtoTakeFromLP = amountLpETH - LPtargetAmount;

      uint256 totalLpToRemove = lpBalance * (ETHtoTakeFromLP / (amountLpETH * 100) / 100);
      liquidityPool.approve(address(unifiRouter), totalLpToRemove);
      (uint256 amountToken, uint256 amountETH) = unifiRouter.removeLiquidityETH(
        address(UPToken),
        totalLpToRemove,
        0,
        0,
        address(this),
        block.timestamp + 150
      );

      strategy.deposit{value: amountETH}(amountETH);
      UPToken.approve(address(UP_CONTROLLER), amountToken);
      UP_CONTROLLER.repay{value: 0}(amountToken);
    } else if (amountLpETH < LPtargetAmount) {
      // Step 6.2
      // calculate the amount of UP / native required. Withdraw native tokens from Strategy, mint the equivlent amount of synthetic UP, Deposit an amount of liquidity so that getupcBalance() = ETHtoTake.
      uint256 ETHtoAddtoLP = ((totalETH * allocationLP) / 100) - amountLpETH;
      strategy.withdraw(ETHtoAddtoLP);
      uint256 lpPrice = (amountLpUP * 1e18) / amountLpETH;
      uint256 UPtoAddtoLP = (lpPrice * ETHtoAddtoLP) / 1e18;
      UP_CONTROLLER.borrowUP(UPtoAddtoLP, address(this));
      UPToken.approve(address(unifiRouter), UPtoAddtoLP);
      unifiRouter.addLiquidityETH{value: ETHtoAddtoLP}(
        address(UPToken),
        UPtoAddtoLP,
        0,
        0,
        address(this),
        block.timestamp + 150
      );
    }
  }

  function _rebalanceWithoutStrategy() internal {
    claimAndBurn();

    // Run arbitrage
    darbi.forceArbitrage();

    (uint256 reservesUP, uint256 reservesETH) = UniswapHelper.getReserves(
      unifiFactory,
      address(UPToken),
      WETH
    );

    (uint256 upLpBalance, uint256 ethLpBalance) = getLiquidityPoolBalance(reservesUP, reservesETH);

    uint256 actualRedeemAmount = (getupcBalance() * allocationRedeem) / 100;
    uint256 actualEthLpAllocation = getupcBalance() - actualRedeemAmount; // ETH

    // IF current LpPrice(95%) > RedeemPrice(95%) = we need to rebalance it to accomplish the rule
    if (ethLpBalance > actualEthLpAllocation) {
      // We get the needed amount of LP token that we need to sell in order to get enough
      // ETH in this contract to rebalance to the redeem target amount.
      uint256 amountToBeWithdrawnFromLp = ethLpBalance - actualEthLpAllocation;
      uint256 diffLpToRemove = (liquidityPool.totalSupply() * amountToBeWithdrawnFromLp) /
        reservesETH;
      uint256 lpBalance = liquidityPool.balanceOf(address(this));
      uint256 totalLpToRemove = lpBalance - diffLpToRemove;

      liquidityPool.approve(address(unifiRouter), totalLpToRemove);
      (uint256 amountToken, uint256 amountETH) = unifiRouter.removeLiquidityETH(
        address(UPToken),
        totalLpToRemove,
        0,
        0,
        address(this),
        block.timestamp + 150
      );

      UPToken.approve(address(UP_CONTROLLER), amountToken);
      UP_CONTROLLER.repay{value: amountETH}(amountToken);
      // IF current RedeemPrice(95%) > LpPrice(95%)
    } else if (ethLpBalance < actualEthLpAllocation) {
      uint256 amountToWithdrawFromRedeem = actualEthLpAllocation - ethLpBalance;
      UP_CONTROLLER.borrowNative(amountToWithdrawFromRedeem, address(this));
      // IF ethLpBalance == 0 = first iteration of the rebalancer
    } else if (ethLpBalance == 0) {
      UP_CONTROLLER.borrowNative(actualEthLpAllocation, address(this));
    }

    uint256 ETHAmountToDeposit = address(this).balance;

    if (ETHAmountToDeposit == 0) return;

    uint256 lpPrice = (reservesETH * 1e18) / reservesUP;
    uint256 UPtoAddtoLP = (ETHAmountToDeposit * 1e18) / lpPrice;

    require(UPtoAddtoLP > 0, "ALREADY_REBALANCED");

    UP_CONTROLLER.borrowUP(UPtoAddtoLP, address(this));
    UPToken.approve(address(unifiRouter), UPtoAddtoLP);
    unifiRouter.addLiquidityETH{value: ETHAmountToDeposit}(
      address(UPToken),
      UPtoAddtoLP,
      0,
      0,
      address(this),
      block.timestamp + 150
    );
  }

  function setStrategy(address newAddress) public onlyAdmin {
    strategy = IStrategy(newAddress);
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

  function setUPController(address newAddress) public onlyAdmin {
    UP_CONTROLLER = UPController(payable(newAddress));
  }

  function setDarbi(address newAddress) public onlyAdmin {
    darbi = Darbi(payable(newAddress));
  }

  function saveReward(IStrategy.Rewards memory reward) internal {
    if (rewards.length == 10) {
      delete rewards[0];
    }
    rewards.push(reward);
  }

  function setAllocationLP(uint256 _allocationLP) public onlyAdmin returns (bool) {
    bool lessthan100 = allocationRedeem + _allocationLP <= 100;
    require(lessthan100, "Allocation for Redeem and LP is over 100%");
    allocationLP = _allocationLP;
    return true;
  }

  function setAllocationRedeem(uint256 _allocationRedeem) public onlyAdmin returns (bool) {
    bool lessthan100 = allocationLP + _allocationRedeem <= 100;
    require(lessthan100, "Allocation for Redeem and LP is over 100%");
    allocationRedeem = _allocationRedeem;
    return true;
  }

  function setSlippageTolerance(uint256 _slippageTolerance) public onlyAdmin returns (bool) {
    bool lessthan10000 = _slippageTolerance <= 10000;
    require(lessthan10000, "Cannot Set Slippage Tolerance over 100%");
    slippageTolerance = _slippageTolerance;
    return true;
  }

  function withdrawFunds(address target) public onlyAdmin returns (bool) {
    return _withdrawFunds(target);
  }

  function withdrawFundsERC20(address target, address tokenAddress)
    public
    onlyAdmin
    returns (bool)
  {
    return _withdrawFundsERC20(target, tokenAddress);
  }

  /// @notice Permissioned function to pause UPToken Controller
  function pause() public onlyAdmin {
    _pause();
  }

  /// @notice Permissioned function to unpause UPToken Controller
  function unpause() public onlyAdmin {
    _unpause();
  }
}
