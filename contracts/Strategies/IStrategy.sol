// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IStrategy {
  /// @notice Deposits an initial or more liquidity in the external contract
  function deposit(uint256 amount) external returns (bool);

  /// @notice Withdraws all the funds deposited in the external contract
  function withdraw(uint256 amount) external returns (bool);

  /// @notice This function will get all the rewards from the external service and send them to the invoker
  function gather() external;
}
