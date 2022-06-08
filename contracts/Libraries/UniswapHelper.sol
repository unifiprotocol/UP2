// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/lib/contracts/libraries/Babylonian.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./FullMath.sol";

library UniswapHelper {
  using SafeMath for uint256;

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
    uint256 reserveB
  ) public pure returns (bool aToB, uint256 amountIn) {
    aToB = FullMath.mulDiv(reserveA, truePriceTokenB, reserveB) < truePriceTokenA;

    uint256 invariant = reserveA.mul(reserveB);

    // The trade ∆a of token a required to move the market to some desired price P' from the current price P can be
    // found with ∆a=(kP')^1/2-Ra.
    uint256 leftSide = Babylonian.sqrt(
      FullMath.mulDiv(
        invariant,
        aToB ? truePriceTokenA : truePriceTokenB,
        aToB ? truePriceTokenB : truePriceTokenA
      )
    );
    uint256 rightSide = (aToB ? reserveA : reserveB);

    if (leftSide < rightSide) return (false, 0);

    // compute the amount that must be sent to move the price back to the true price.
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

  function sortTokens(address tokenA, address tokenB)
    internal
    pure
    returns (address token0, address token1)
  {
    require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(
    address factory,
    address tokenA,
    address tokenB
  ) internal pure returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex"ff",
              factory,
              keccak256(abi.encodePacked(token0, token1)),
              hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
            )
          )
        )
      )
    );
  }
}
