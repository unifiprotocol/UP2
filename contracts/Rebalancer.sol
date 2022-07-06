// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Libraries/UniswapHelper.sol";
import "./Interfaces/UnifiPair.sol";
import "./UPController.sol";
import "./UP.sol";
import "./Strategies/IStrategy.sol";
import "./Helpers/Safe.sol";
import "./Darbi/Darbi.sol";

contract Rebalancer is AccessControl, Pausable, Safe {
  using SafeERC20 for IERC20;

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
    setStrategy(_Strategy);
    UPToken = UP(payable(_UPAddress));
    unifiRouter = IUniswapV2Router02(_unifiRouter);
    unifiFactory = _unifiFactory;
    liquidityPool = IUnifiPair(payable(_liquidityPool));
    darbi = Darbi(payable(_darbi));
  }

  receive() external payable {}

  function claimAndBurn() internal {
    uint256 claimedUP = liquidityPool.claimUP(address(this));
    UPToken.approve(address(UPToken), claimedUP);
    UPToken.justBurn(claimedUP);
  }

  function getupcBalance() internal view returns (uint256 upcBalance) {
    upcBalance = address(UP_CONTROLLER).balance;
  }

  function rebalance() public whenNotPaused onlyRebalance {
    // Step 1
    claimAndBurn();

    IERC20 lp = IERC20(address(liquidityPool));

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
    darbi.arbitrage();

    (uint256 amountLpUP, uint256 amountLpETH) = checkLiquidityPoolBalance();
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
    uint256 lpBalance = lp.balanceOf(address(this));
    uint256 backedValue = UP_CONTROLLER.getVirtualPrice();
    (uint256 reserves0, uint256 reserves1) = UniswapHelper.getReserves(
      unifiFactory,
      address(UPToken),
      WETH
    );
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

      uint256 totalLpToRemove = lpBalance * (amountLpETH / (ETHtoTakeFromLP * 100) / 100);
      address liquidityPoolAddress = address(liquidityPool);
      IERC20(liquidityPoolAddress).approve(address(unifiRouter), totalLpToRemove);
      (uint256 amountToken, uint256 amountETH) = unifiRouter.removeLiquidityETH(
        liquidityPoolAddress,
        totalLpToRemove,
        0,
        0,
        address(this),
        block.timestamp + 20 minutes
      );

      strategy.deposit{value: amountETH}(amountETH);
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
        address(liquidityPool),
        UPtoAddtoLP,
        0,
        0,
        address(this),
        block.timestamp + 20 minutes
      );
    }
  }

  function checkLiquidityPoolBalance() public view returns (uint256, uint256) {
    IERC20 lp = IERC20(address(liquidityPool));
    uint256 lpBalance = lp.balanceOf(address(this));
    if (lpBalance == 0) {
      return (0, 0);
    }
    (bool success, bytes memory result) = address(unifiRouter).staticcall(
      abi.encodeWithSignature(
        "removeLiquidityETH(address,uint,uint,uint,address,uint)",
        address(liquidityPool),
        lpBalance,
        0,
        0,
        address(this),
        block.timestamp + 150
      )
    );
    require(success);
    (uint256 amountLpUP, uint256 amountLpETH) = abi.decode(result, (uint256, uint256));
    return (amountLpUP, amountLpETH);
  }

  function setUPController(address newAddress) public onlyAdmin {
    UP_CONTROLLER = UPController(payable(newAddress));
  }

  function setStrategy(address newAddress) public onlyAdmin {
    strategy = IStrategy(newAddress);
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
