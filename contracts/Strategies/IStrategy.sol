// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IStrategy {
  struct Rewards {
    uint256 rewardsAmount;
    uint256 depositedAmount;
    uint256 timestamp;
  }

  /// @notice Deposits an initial or more liquidity in the external contract
  function deposit(uint256 amount) external payable returns (bool);

  /// @notice Withdraws all the funds deposited in the external contract
  function withdraw(uint256 amount) external returns (bool);

  function withdrawAll() external returns (bool);

  /// @notice This function will get all the rewards from the external service and send them to the invoker
  function gather() external;

  /// @notice Returns the amount staked plus the earnings
  function checkRewards() external view returns (Rewards memory);

  ///@notice Returns the amount deposited
  function amountDeposited() external view returns (uint256);
}
