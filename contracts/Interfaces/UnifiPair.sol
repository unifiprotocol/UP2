// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@uniswap/v2-core/contracts/UniswapV2Pair.sol";

interface IUnifiPair is UniswapV2Pair {
  function claimUP(address to) external returns (uint256 upReceived);
}
