// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol";
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
  uint256[3] public distribution = [90, 5, 5];
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
    UP(UPaddress).justBurn(claimedUP);
  }

  function rebalance() public onlyAdmin {
    claimAndBurn();

    // Store a snapshot of the rewards
    IStrategy.Rewards memory strategyRewards = IStrategy(strategy).checkRewards();
    saveReward(strategyRewards);

    // Gather the generated rewards by the strategy and send them to the UPController
    IStrategy(strategy).gather();
    (bool successUpcTransfer, ) = UP_CONTROLLER.call{value: strategyRewards.rewardsAmount}("");
    require(successUpcTransfer, "FAIL_SENDING_REWARDS_TO_UPC");
    // UPController balances after get rewards
    uint256 upcBalance = address(UP_CONTROLLER).balance;

    // Estimates the amount of ETH in the LP
    uint256 amountLpETH = checkLiquidityPoolBalance();

    uint256 totalETH = amountLpETH + upcBalance + strategyRewards.depositedAmount;

    // Force arbitrage
    address[2] memory swappedTokens = [UP_TOKEN, address(WETH)];
    (uint256 reserveA, uint256 reserveB) = UniswapHelper.getReserves(
      unifiFactory,
      swappedTokens[0],
      swappedTokens[1]
    );
    (bool aToB, uint256 amountIn) = Darbi(darbi).moveMarketBuyAmount();

    if (aToB) {
      uint256 amountsOut = UniswapV2Library.getAmountOut(amountIn, reserveA, reserveB);
      uint256 virtualPrice = UPController.getVirtualPrice();
      uint256 expectedRedeemAmount = amountsOut * virtualPrice;
      if (address(UP_CONTROLLER).balance < expectedRedeemAmount) {
        //Take money from the strategy - 5% of the total of the strategy
        uint256 ETHtoTake = (totalETH / 20) - upcBalance;
        IStrategy(strategy).withdraw{value: ETHtoTake}(ETHtoTake);
      }
      return;
    } else {
      // I have to mint UP
      Darbi(darbi).arbitrage();
      // REFRESH`
      upcBalance = address(UP_CONTROLLER).balance;
      amountLpETH = checkLiquidityPoolBalance();

      uint256 totalETH = amountLpETH + upcBalance + strategyRewards.depositedAmount;
      //Take money from the strategy - 5% of the total of the strategy
      uint256 ETHtoTake = (totalETH / 20) - upcBalance;
      if (address(UP_CONTROLLER).balance > ETHtoTake) {
        uint256 amountToWithdraw = address(UP_CONTROLLER).balance - ETHtoTake;
        IStrategy(strategy).deposit{value: amountToWithdraw}(amountToWithdraw);
      } else if (address(UP_CONTROLLER).balance < ETHtoTake) {
        uint256 amountToDeposit = ETHtoTake - address(UP_CONTROLLER).balance;
        IStrategy(strategy).deposit{value: amountToWithdraw}(amountToWithdraw);
      }

      if (upcBalance > ETHtoTake) {
        // withdraw the amount of LP so that upcBalance = ETHtoTake, send native tokens to Strategy, 'repay' / burn the synthetic UP withdrawn
      } else if (upcBalance < ETHtoTake) {
        // calculate the amount of UP / native required. Withdraw native tokens from Strategy, mint the equivlent amount of synthetic UP, Deposit an amount of liquidity so that upcBalance = ETHtoTake.
      }

      //That's it my dude
    }

  //   uint256 distribution1 = ((totalETH * (distribution[0] * 100)) / 10000);
  //   uint256 distribution2 = ((totalETH * (distribution[1] * 100)) / 10000);
  //   uint256 distribution3 = ((totalETH * (distribution[2] * 100)) / 10000);
  //   _distribution1(distribution1);
  //   _distribution2(distribution2);
  //   _distribution3(distribution3);
  // }

  function checkLiquidityPoolBalance() public view returns (uint256) {
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
    require(success, "FAIL_ESTIMATING_LP_SUPPLY");
    (, uint256 amountLpETH) = abi.decode(result, (uint256, uint256));
    return amountLpETH;
  }

  function _distribution1(uint256 _amount) internal {
    /// distribution 1 goes to the strategy
    IStrategy(strategy).deposit(_amount);
  }

  function _distribution2(uint256 _amount) internal {
    /// distribution 2 goes to the Unifi LP
    (uint256 reserves0, uint256 reserves1) = UniswapHelper.getReserves(
      unifiFactory,
      UPaddress,
      WETH
    );
    uint256 lpPrice = (reserves0 * 1e18) / reserves1;
    uint256 borrowAmount = lpPrice * _amount;
    UPController(UP_CONTROLLER).borrowUP(borrowAmount, address(this));
    uint256 distribution2Slippage = ((_amount * (1 * 100)) / 10000); // 1%
    uint256 amountTokenMin = ((borrowAmount * (1 * 100)) / 10000); // 1%
    unifiRouter.addLiquidityETH(
      UPaddress,
      _amount,
      amountTokenMin,
      distribution2Slippage,
      address(this),
      block.timestamp + 20 minutes
    );
  }

  function _distribution3(uint256 _amount) internal {
    /// distribution 3 goes to the UPController
    (bool successTransfer, ) = address(UP_CONTROLLER).call{value: _amount}("");
    require(successTransfer, "DISTRIBUTION3_FAILED");
  }

  // Alternative, withdraw 5% of the total native token bal;ance of UPC from the Strategy, and send them to the UPC

  // GETTER & SETTERS
  function setDistribution(uint256[3] memory _distribution) public onlyAdmin {
    require(_distribution[0] > 0, "INVALID_PARAM_0");
    require(_distribution[1] > 0, "INVALID_PARAM_1");
    require(_distribution[2] > 0, "INVALID_PARAM_2");
    require((_distribution[0] + _distribution[1] + _distribution[2]) == 100, "INVALID_PARAMS");
    distribution = _distribution;
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
