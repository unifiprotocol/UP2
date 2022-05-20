// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/lib/contracts/libraries/Babylonian.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol";
import "@uniswap/v2-periphery/contracts/libraries/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../Helpers/Safe.sol";
import "../Libraries/UniswapV2LiquidityMathLibrary.sol";

contract Darbi is AccessControl, Pausable, Safe {
  bytes32 public constant MONITOR_ROLE = keccak256("MONITOR_ROLE");
  bytes32 public constant REBALANCER_ROLE = keccak256("REBALANCER_ROLE");
  using SafeMath for uint256;

  IUniswapV2Router01 public router;
  address public factory;

  modifier onlyMonitor() {
    require(hasRole(MONITOR_ROLE, msg.sender), "ONLY_MONITOR");
    _;
  }

  modifier onlyRebalancer() {
    require(hasRole(REBALANCER_ROLE, msg.sender), "ONLY_REBALANCER");
    _;
  }

  constructor(address factory_, IUniswapV2Router01 router_) {
    factory = factory_;
    router = router_;
  }

  // swaps an amount of either token such that the trade is profit-maximizing, given an external true price
  // true price is expressed in the ratio of token A to token B
  // caller must approve this contract to spend whichever token is intended to be swapped
  function swapToPrice(
    address tokenA,
    address tokenB,
    uint256 truePriceTokenA,
    uint256 truePriceTokenB,
    uint256 maxSpendTokenA,
    uint256 maxSpendTokenB,
    address to,
    uint256 deadline
  ) public onlyMonitor onlyRebalancer {
    // true price is expressed as a ratio, so both values must be non-zero
    require(truePriceTokenA != 0 && truePriceTokenB != 0, "ExampleSwapToPrice: ZERO_PRICE");
    // caller can specify 0 for either if they wish to swap in only one direction, but not both
    require(maxSpendTokenA != 0 || maxSpendTokenB != 0, "ExampleSwapToPrice: ZERO_SPEND");

    bool aToB;
    uint256 amountIn;
    {
      (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
      (aToB, amountIn) = UniswapV2LiquidityMathLibrary.computeProfitMaximizingTrade(
        truePriceTokenA,
        truePriceTokenB,
        reserveA,
        reserveB
      );
    }

    require(amountIn > 0, "ExampleSwapToPrice: ZERO_AMOUNT_IN");

    // spend up to the allowance of the token in
    uint256 maxSpend = aToB ? maxSpendTokenA : maxSpendTokenB;
    if (amountIn > maxSpend) {
      amountIn = maxSpend;
    }

    address tokenIn = aToB ? tokenA : tokenB;
    address tokenOut = aToB ? tokenB : tokenA;
    TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
    TransferHelper.safeApprove(tokenIn, address(router), amountIn);

    address[] memory path = new address[](2);
    path[0] = tokenIn;
    path[1] = tokenOut;

    router.swapExactTokensForTokens(
      amountIn,
      0, // amountOutMin: we can skip computing this number because the math is tested
      path,
      to,
      deadline
    );
  }
}
