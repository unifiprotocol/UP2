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

  bytes32 public constant STAKING_ROLE = keccak256("STAKING_ROLE");

  address public WETH = address(0);
  address public strategy = address(0);
  address public unifiFactory = address(0);
  address public liquidityPool = address(0);
  address payable public darbi = payable(address(0));
  address payable public UPaddress = payable(address(0));
  address payable public UP_CONTROLLER = payable(address(0));
  uint256 public allocationLP = 5; //Whole Number for Percent, i.e. 5 = 5%
  uint256 public allocationRedeem = 5; //Whole Number for Percent, i.e. 5 = 5%
  uint256 public slippageTolerance = 10; //Percent with 2 Percision, i.e. 10 = 0.1%

  IUniswapV2Router02 public unifiRouter;
  IStrategy.Rewards[] public rewards;

  modifier onlyStaking() {
    require(hasRole(STAKING_ROLE, msg.sender), "ONLY_STAKING");
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
    WETH = _WETH;
    UPaddress = payable(_UPAddress);
    UP_CONTROLLER = payable(_UPController);
    strategy = _Strategy;
    unifiRouter = IUniswapV2Router02(_unifiRouter);
    unifiFactory = _unifiFactory;
    liquidityPool = _liquidityPool;
    darbi = payable(_darbi);
  }

  receive() external payable {}

  function claimAndBurn() internal {
    uint256 claimedUP = IUnifiPair(liquidityPool).claimUP(address(this));
    UP(UPaddress).approve(UPaddress, claimedUP);
    UP(UPaddress).justBurn(claimedUP);
  }

  function getupcBalance() internal view returns (uint256 upcBalance) {
    upcBalance = address(UP_CONTROLLER).balance;
  }

  function rebalance() public whenNotPaused onlyAdmin {
    claimAndBurn();

    IERC20 lp = IERC20(liquidityPool);
    uint256 lpBalance = lp.balanceOf(address(this)); //Put in Variable Defination

    UPController upController = UPController(UP_CONTROLLER); // Put in Variable Defination

    // Store a snapshot of the rewards
    IStrategy.Rewards memory strategyRewards = IStrategy(strategy).checkRewards();
    saveReward(strategyRewards);

    // Gather the generated rewards by the strategy and send them to the UPController
    IStrategy(strategy).gather();
    (bool successUpcTransfer, ) = UP_CONTROLLER.call{value: strategyRewards.rewardsAmount}("");
    require(successUpcTransfer, "FAIL_SENDING_REWARDS_TO_UPC");
    // UPController balances after get rewards

    // Estimates the amount of ETH in the LP
    (, uint256 amountLpETH) = checkLiquidityPoolBalance();

    uint256 totalETH = amountLpETH + getupcBalance() + strategyRewards.depositedAmount;

    // Force Arbitrage
    Darbi(darbi).arbitrage();

    // REFRESH`
    uint256 amountLpUP;
    (amountLpUP, amountLpETH) = checkLiquidityPoolBalance();

    totalETH = amountLpETH + getupcBalance() + strategyRewards.depositedAmount;
    //Take money from the strategy - 5% of the total of the strategy
    uint256 ETHtoTake = ((totalETH * allocationRedeem) / 100) - getupcBalance();
    if (address(UP_CONTROLLER).balance > ETHtoTake) {
      uint256 amountToWithdraw = address(UP_CONTROLLER).balance - ETHtoTake;
      IStrategy(strategy).deposit{value: amountToWithdraw}(amountToWithdraw);
    } else if (address(UP_CONTROLLER).balance < ETHtoTake) {
      uint256 amountToDeposit = ETHtoTake - address(UP_CONTROLLER).balance;
      IStrategy(strategy).deposit{value: amountToDeposit}(amountToDeposit);
    }

    // REBALANCE LP
    lpBalance = lp.balanceOf(address(this));
    uint256 backedValue = UPController(UP_CONTROLLER).getVirtualPrice() / 1e18;
    (uint256 reserves0, uint256 reserves1) = UniswapHelper.getReserves(unifiFactory, UPaddress, WETH);
    uint256 marketValue = reserves0 / reserves1;
    if (backedValue > (marketValue * (1 + (slippageTolerance / 10000))) || backedValue < (marketValue * (1 - (slippageTolerance / 10000)))) {
      return;
    }
    if (amountLpETH > ETHtoTake) {
      // withdraw the amount of LP so that getupcBalance() = ETHtoTake, send native tokens to Strategy, 'repay' / burn the synthetic UP withdrawn
      uint256 ETHtoTakeFromLP = amountLpETH - ((totalETH * allocationLP) / 100);
      uint256 diff = amountLpETH / (ETHtoTakeFromLP * 100);

      uint256 totalLpToRemove = lpBalance * (diff / 100);
      IERC20(liquidityPool).approve(address(unifiRouter), totalLpToRemove);

      (uint256 amountToken, uint256 amountETH) = unifiRouter.removeLiquidityETH(
        liquidityPool,
        totalLpToRemove,
        0,
        0,
        address(this),
        block.timestamp + 20 minutes
      );

      IStrategy(strategy).deposit{value: amountETH}(amountETH);
      UPController(UP_CONTROLLER).repay{value: 0}(amountToken);
    } else if (amountLpETH < ETHtoTake) {
      // calculate the amount of UP / native required. Withdraw native tokens from Strategy, mint the equivlent amount of synthetic UP, Deposit an amount of liquidity so that getupcBalance() = ETHtoTake.
      uint256 ETHtoAddtoLP = ((totalETH * allocationLP)/ 100) - amountLpETH;
      uint256 lpPrice = amountLpUP / amountLpETH;
      uint256 UPtoAddtoLP = lpPrice * ETHtoAddtoLP;
      upController.borrowUP(UPtoAddtoLP, address(this));
      unifiRouter.addLiquidityETH{value: ETHtoAddtoLP}(
        liquidityPool,
        UPtoAddtoLP,
        0,
        0,
        address(this),
        block.timestamp + 20 minutes
      );
    }
  }

  function checkLiquidityPoolBalance() public view returns (uint256, uint256) {
    IERC20 lp = IERC20(liquidityPool);
    uint256 lpBalance = lp.balanceOf(address(this));
    (bool success, bytes memory result) = address(unifiRouter).staticcall(
      abi.encodeWithSignature(
        "removeLiquidityETH(address,uint,uint,uint,address,uint)",
        liquidityPool,
        lpBalance,
        0,
        0,
        address(this),
        block.timestamp + 20 minutes
      )
    );
    if (!success) {
      // No LP Balance
      return (0, 0);
    }
    (uint256 amountLpUP, uint256 amountLpETH) = abi.decode(result, (uint256, uint256));
    return (amountLpUP, amountLpETH);
  }

  function setUPController(address newAddress) public onlyAdmin {
    UP_CONTROLLER = payable(newAddress);
  }

  function setStrategy(address newAddress) public onlyAdmin {
    strategy = newAddress;
  }

  function setUnifiRouter(address newAddress) public onlyAdmin {
    unifiRouter = IUniswapV2Router02(newAddress);
  }

  function setDarbi(address newAddress) public onlyAdmin {
    darbi = payable(newAddress);
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

  /// @notice Permissioned function to pause UPaddress Controller
  function pause() public onlyAdmin {
    _pause();
  }

  /// @notice Permissioned function to unpause UPaddress Controller
  function unpause() public onlyAdmin {
    _unpause();
  }
}
