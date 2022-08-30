// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./StakingPrecompiles.sol";

contract MockedStakingPrecompiles is IStakingPrecompiles {
  struct Undelegation {
    uint256 targetEpoch;
    uint256 amount;
    bool pending;
  }

  uint256 currentEpoch = 0;
  uint256 totalRewards = 0;
  uint256 depositedAmount = 0;
  uint256 undelegatedAmount = 0;

  Undelegation undelegation;

  uint256 constant percentageEpochYield = 205; //  0.0205% of epoch yield

  function delegate(address) public payable override returns (uint256) {
    depositedAmount += msg.value;
    return msg.value;
  }

  function undelegate(address, uint256 amount) public override returns (uint256) {
    require(!undelegation.pending, "MockedStakingPrecompiles: An undelegation is still processing");
    require(
      amount <= depositedAmount,
      "MockedStakingPrecompiles: Undelegate amount cannot exceed deposited amount."
    );
    undelegation = Undelegation(currentEpoch + 8, amount, true);
    depositedAmount -= amount;
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "MockedStakingPrecompiles: Error sending ETH");
    return amount;
  }

  function collectRewards() public override returns (uint256) {
    uint256 amount = totalRewards;
    totalRewards = 0;
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "MockedStakingPrecompiles: FAIL_SENDING_NATIVE");
    return amount;
  }

  function epoch() public view override returns (uint256) {
    return currentEpoch;
  }

  function calculateRewards(uint256 numberOfEpochs) public view returns (uint256) {
    return (numberOfEpochs * percentageEpochYield * depositedAmount) / 1e6;
  }

  function advanceEpoch(uint256 numberOfEpochs) public payable {
    uint256 generatedRewards = calculateRewards(numberOfEpochs);
    require(
      msg.value == generatedRewards,
      "MockedStakingPrecompiles: trx value doens't match with rewards"
    );
    currentEpoch += numberOfEpochs;
    totalRewards += generatedRewards;
    if (undelegation.pending && currentEpoch > undelegation.targetEpoch) {
      undelegatedAmount += undelegation.amount;
      undelegation = Undelegation(0, 0, false);
    }
  }

  function withdrawUndelegatedFunds() external override returns (uint256) {
    uint256 amount = undelegatedAmount;
    undelegatedAmount = 0;
    require(
      undelegatedAmount <= address(this).balance,
      "MockedStakingPrecompiles: Undelegated amount exceeed contract balance."
    );
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "MockedStakingPrecompiles: FAIL_SENDING_NATIVE");
    return undelegatedAmount;
  }
}
