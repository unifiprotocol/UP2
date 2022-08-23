// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Strategy.sol";
import "../Helpers/StakingPrecompiles.sol";
import "../UPController.sol";

// Contract Strategy must use our customized Safe.sol and OpenZeppelin's AccessControl and Pauseable Contracts.
// Safe.sol is utilized so the DAO can retrieve any lost assets within the Strategy Contract.
// AccessControl.sol is utilized so only the Rebalancer can interact with the strategy, and only the DAO can update the Rebalancer Contract.
// Pausable.sol is utilized so that DAO can pause the strategy in an emergency.

// Contract Strategy must use our customized Safe.sol and OpenZeppelin's AccessControl and Pauseable Contracts.
// Safe.sol is utilized so the DAO can retrieve any lost assets within the Strategy Contract.
// AccessControl.sol is utilized so only the Rebalancer can interact with the strategy, and only the DAO can update the Rebalancer Contract.
// Pausable.sol is utilized so that DAO can pause the strategy in an emergency.

contract HarmonyStakingStrategy is Strategy, StakingPrecompiles {
  /// @notice The amountStaked MUST reflect the amount of native tokens currently deposited into other contracts. All deposits and withdraws so update this variable.
  uint256 public epochOfLastRebalance = 0;
  uint256 public amountStaked = 0;
  uint256 public lastClaimedAmount = 0;
  address public targetValidator;

  UPController public upController;

  constructor(
    address _fundsTarget,
    address _targetValidator,
    address _upController
  ) Strategy(_fundsTarget) {
    upController = UPController(payable(_upController));
    targetValidator = _targetValidator;
  }

  // Read Functions

  ///@notice The public checkRewards function MUST return a struct with the amount of pending rewards valued in native tokens, the total amount deposited, and the block timestamp.
  ///For example, if 500 NativeTokens are deposited, and the strategy has earned 5 Native Tokens and 2 of TokenA,
  ///the function should calculate the return for selling 2 TokenA, and add to the 5 Native Tokens.
  ///If we assume that each TokenA is worth 4 native tokens, then the unclaimedEarnings value should return a value of 13, adjusted for percision.

  function checkAllocation() public pure returns (uint256 allocationOthers) {
    return 10;
  }

  function rewardsAmount() public view returns (uint256) {
    (bool success, bytes memory response) = address(this).staticcall(
      abi.encodeWithSignature("collectRewards()")
    );
    require(success, "Failed to Fetch Pending Rewards Amount");
    uint256 result = abi.decode(response, (uint256));
    return result;
  }

  function checkRewards() public view override returns (IStrategy.Rewards memory) {
    IStrategy.Rewards memory result = IStrategy.Rewards(
      lastClaimedAmount,
      amountStaked,
      block.timestamp
    );
    return result;
  }

  // Write Functions
  function adjustDelegation() public onlyAdmin whenNotPaused returns (bool) {
    uint256 currentAllocation = checkAllocation();
    require(currentAllocation <= 100, "Allocation for LP and Redeem exceeds 100%");
    uint256 targetAmountToStake = (200000000000000000000 * (100 - currentAllocation)) / 100;
    //logic bug is here
    if (targetAmountToStake > amountStaked) {
      uint256 amountToStake = targetAmountToStake - amountStaked; // This number
      require(
        amountToStake < address(this).balance,
        "Strategy does not have enough native tokens to add to stake"
      );
      delegate(targetValidator, amountToStake);
      amountStaked += amountToStake;
    }
    if (targetAmountToStake < amountStaked) {
      uint256 amountToUnstake = targetAmountToStake - amountStaked;
      require(
        amountToUnstake < amountStaked,
        "Stake does not have enough of a balance to undelegate"
      );
      undelegate(targetValidator, amountToUnstake);
      amountStaked -= amountToUnstake;
    }
    return true;
  }

  ///@notice The gather function should claim all yield earned from the native tokens while leaving the amount deposited intact.
  ///Then, this function should send all earnings to the rebalancer contract. This function MUST only send native tokens to the rebalancer.
  ///For example, if the tokens are deposited in a lending protocol, it should the totalBalance minus the amountDeposited.

  function gather() public override onlyRebalancer whenNotPaused {
    uint256 currentEpoch = epoch();
    require(
      currentEpoch > epochOfLastRebalance + 7,
      "Seven epoches have not passed since last rebalance"
    );
    uint256 balanceBefore = address(this).balance;
    //Check through console.logs if this too is affected by Smart Contract / Assembly schism
    collectRewards();
    uint256 balanceAfter = address(this).balance;
    uint256 claimedRewards = balanceAfter - balanceBefore;
    lastClaimedAmount = claimedRewards;
    checkRewards();
    (bool successTransfer, ) = address(msg.sender).call{value: claimedRewards}("");
    require(successTransfer, "FAIL_SENDING_NATIVE");
    epochOfLastRebalance = currentEpoch;
  }
}
