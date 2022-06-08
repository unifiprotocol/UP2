// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUnifiPair {
  function claimUP(address to) external returns (uint256 upReceived);
}
