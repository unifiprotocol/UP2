// SPDX-License-Identifier: MIT

pragma solidity =0.6.6;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/lib/contracts/libraries/Babylonian.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol";
import "../Libraries/UniswapV2LiquidityMathLibrary.sol";

contract Darbi {
  using SafeMath for uint256;

  IUniswapV2Router02 public router;
  address public factory;
  mapping(address => bool) admins;

  modifier onlyAdmin() {
    require(admins[msg.sender] == true, "ONLY_ADMIN");
    _;
  }

  constructor(address _factory, address _router) public {
    factory = _factory;
    router = IUniswapV2Router02(_router);
    admins[msg.sender] = true;
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
  ) public onlyAdmin {
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

  function setAdmin(address _newAdmin) public onlyAdmin {
    require(_newAdmin != address(0));
    admins[_newAdmin] = true;
  }

  function removeAdmin(address _adminAddr) public onlyAdmin {
    require(_adminAddr != address(0));
    admins[_adminAddr] = false;
  }
}
