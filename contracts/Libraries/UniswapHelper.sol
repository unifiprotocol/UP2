// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/lib/contracts/libraries/Babylonian.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./FullMath.sol";

library UniswapHelper {
  using SafeMath for uint256;

  // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut,
    uint256 tradingFee
  ) internal pure returns (uint256 amountOut) {
    uint256 tradingFeeFactor = 10000 - tradingFee;
    require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
    require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
    uint256 amountInWithFee = amountIn * tradingFeeFactor;
    uint256 numerator = amountInWithFee * reserveOut;
    uint256 denominator = reserveIn * 10000 + amountInWithFee;
    amountOut = numerator / denominator;
  }

  // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut,
    uint256 tradingFee
  ) internal pure returns (uint256 amountIn) {
    uint256 tradingFeeFactor = 10000 - tradingFee;
    require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
    require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
    uint256 numerator = reserveIn.mul(amountOut).mul(10000);
    uint256 denominator = reserveOut.sub(amountOut).mul(tradingFeeFactor);
    amountIn = (numerator / denominator).add(1);
  }

  // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) internal pure returns (uint256 amountB) {
    require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
    require(reserveA > 0 && reserveB > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
    amountB = (amountA * reserveB) / reserveA;
  }

  /**
   * @notice Given the "true" price a token (represented by truePriceTokenA/truePriceTokenB) and the reservers in the
   * uniswap pair, calculate: a) the direction of trade (aToB) and b) the amount needed to trade (amountIn) to move
   * the pool price to be equal to the true price.
   * @dev Note that this method uses the Babylonian square root method which has a small margin of error which will
   * result in a small over or under estimation on the size of the trade needed.
   * @param truePriceTokenA the nominator of the true price.
   * @param truePriceTokenB the denominator of the true price.
   * @param reserveA number of token A in the pair reserves
   * @param reserveB number of token B in the pair reserves
   */
  //
  function computeTradeToMoveMarket(
    uint256 truePriceTokenA,
    uint256 truePriceTokenB,
    uint256 reserveA,
    uint256 reserveB,
    uint256 tradingFee
  ) public pure returns (bool aToB, uint256 amountIn) {
    aToB = FullMath.mulDiv(reserveA, truePriceTokenB, reserveB) < truePriceTokenA;

    uint256 invariant = reserveA.mul(reserveB);
    uint256 tradingFeeFactor = 10000 - tradingFee;
    uint256 leftSide = Babylonian.sqrt(
      FullMath.mulDiv(
        invariant.mul(10000),
        aToB ? truePriceTokenA : truePriceTokenB,
        (aToB ? truePriceTokenB : truePriceTokenA).mul(tradingFeeFactor)
      )
    );
    uint256 rightSide = (aToB ? reserveA.mul(10000) : reserveB.mul(10000)) / tradingFeeFactor;

    if (leftSide < rightSide) return (false, 0);

    amountIn = leftSide.sub(rightSide);
  }

  // The methods below are taken from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
  // We could import this library into this contract but this library is dependent Uniswap's SafeMath, which is bound
  // to solidity 6.6.6. UMA uses 0.8.0 and so a modified version is needed to accomidate this solidity version.
  function getReserves(
    address factory,
    address tokenA,
    address tokenB
  ) public view returns (uint256 reserveA, uint256 reserveB) {
    (address token0, ) = sortTokens(tokenA, tokenB);
    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB))
      .getReserves();
    (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
  }

  function sortTokens(
    address tokenA,
    address tokenB
  ) internal pure returns (address token0, address token1) {
    require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
  }

  function pairFor(
    address factory,
    address tokenA,
    address tokenB
  ) public view returns (address pair) {
    return IUniswapV2Factory(factory).getPair(tokenA, tokenB);
  }
}
