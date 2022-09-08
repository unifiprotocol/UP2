// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./HarmonyStakingStrategyDecoupled.sol";
import "hardhat/console.sol";

// Contract Strategy must use our customized Safe.sol and OpenZeppelin's AccessControl and Pauseable Contracts.
// Safe.sol is utilized so the DAO can retrieve any lost assets within the Strategy Contract.
// AccessControl.sol is utilized so only the Rebalancer can interact with the strategy, and only the DAO can update the Rebalancer Contract.
// Pausable.sol is utilized so that DAO can pause the strategy in an emergency.

contract TestingHarmonyStakingStrategy is HarmonyStakingStrategy {
  constructor(
    address _fundsTarget,
    address _targetValidator,
    address _upController,
    address _rebalancer
  ) HarmonyStakingStrategy(_fundsTarget, _targetValidator, _upController, _rebalancer) {}

  function afterDelegate(uint256 amountToStake) public {
    _afterDelegate(amountToStake);
  }

  function afterUndelegate(uint256 amountToUnstake) public {
    _afterUndelegate(amountToUnstake);
  }

  function afterGather(uint256 currentEpoch) public {
    _afterGather(currentEpoch);
  }

  function afterUndelegateAll(uint256 currentEpoch) public {
    _afterUndelegateAll(currentEpoch);
  }

  function drainStrategyBalance() public {
    _drainStrategyBalance();
  }

  function setTestingConditions(
    uint256 targetBalance,
    uint256 targetAmountStaked,
    uint256 targetPendingUndelegation,
    uint256 targetLastClaimedAmount
  ) public payable {
    uint256 currentBalance = address(this).balance;
    if (currentBalance > targetBalance) {
      (bool success, ) = msg.sender.call{value: currentBalance - targetBalance}("");
      require(success, "TestingHarmonyStakingStrategy: FAILED_SENDING_NATIVE");
    }
    require(
      address(this).balance == targetBalance,
      "TestingHarmonyStakingStrategy: FAILED_SETTING_BALANCE"
    );
    amountStaked = targetAmountStaked;
    pendingUndelegation = targetPendingUndelegation;
    lastClaimedAmount = targetLastClaimedAmount;
    amountDeposited = amountStaked + address(this).balance + pendingUndelegation;
  }
}
