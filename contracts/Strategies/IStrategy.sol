// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IStrategy {
  function deposit(uint256 amount) external returns (bool);

  function withdraw(uint256 amount) external returns (bool);

  function gather() external;
}
