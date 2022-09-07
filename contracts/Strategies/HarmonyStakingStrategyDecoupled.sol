// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Strategy.sol";
import "../Helpers/Safe.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../UPController.sol";
import "../Rebalancer.sol";
import "../Helpers/StakingPrecompiles.sol";

// Contract Strategy must use our customized Safe.sol and OpenZeppelin's AccessControl and Pauseable Contracts.
// Safe.sol is utilized so the DAO can retrieve any lost assets within the Strategy Contract.
// AccessControl.sol is utilized so only the Rebalancer can interact with the strategy, and only the DAO can update the Rebalancer Contract.
// Pausable.sol is utilized so that DAO can pause the strategy in an emergency.

contract HarmonyStakingStrategy is Strategy, StakingPrecompiles {
  bytes32 public constant MONITOR_ROLE = keccak256("MONITOR_ROLE");

  /// @notice The amountDeposited MUST reflect the amount of native tokens currently deposited into other contracts. All deposits and withdraws so update this variable.
  uint256 public amountStaked = 0;
  uint256 public epochOfLastRebalance = 0;
  uint256 public lastClaimedAmount = 0;
  uint256 public pendingUndelegation = 0;
  uint256 public timestampOfLastClaim = 0;
  address public targetValidator;
  address public monitor;

  UPController public upController;
  Rebalancer public rebalancer;

  modifier onlyMonitor() {
    require(hasRole(MONITOR_ROLE, msg.sender), "ONLY_MONITOR");
    _;
  }

  event UpdateRebalancer(address rebalancer);
  event UpdateUPController(address upController);
  event UpdateValidator(address targetValidator);

  constructor(
    address _fundsTarget,
    address _targetValidator,
    address _upController,
    address _rebalancer
  ) Strategy(_fundsTarget) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(REBALANCER_ROLE, msg.sender);
    _setupRole(MONITOR_ROLE, msg.sender);
    targetValidator = _targetValidator;
    upController = UPController(payable(_upController));
    rebalancer = Rebalancer(payable(_rebalancer));
  }

  // Read Functions

  ///@notice The public checkRewards function MUST return a struct with the amount of pending rewards valued in native tokens, the total amount deposited, and the block timestamp.
  ///For example, if 500 NativeTokens are deposited, and the strategy has earned 5 Native Tokens and 2 of TokenA,
  ///the function should calculate the return for selling 2 TokenA, and add to the 5 Native Tokens.
  ///If we assume that each TokenA is worth 4 native tokens, then the unclaimedEarnings value should return a value of 13, adjusted for percision.

  function checkAllocation() public view virtual returns (uint256) {
    return rebalancer.allocationLP() + rebalancer.allocationRedeem();
  }

  function rewardsAmount() public view returns (uint256) {
    (bool success, bytes memory response) = address(this).staticcall(
      abi.encodeWithSignature("collectRewards()")
    );
    require(success, "Failed to Fetch Pending Rewards Amount");
    uint256 result = abi.decode(response, (uint256));
    return result;
  }

  function checkRewards() public view virtual override returns (IStrategy.Rewards memory) {
    IStrategy.Rewards memory result = IStrategy.Rewards(
      lastClaimedAmount,
      amountDeposited,
      timestampOfLastClaim
    );
    return result;
  }

  // Write Functions

  function adjustDelegation() public onlyMonitor whenNotPaused returns (bool) {
    uint256 targetAmountToStake = getTargetStakeAmount();
    uint256 MINIMUM_AMOUNT_FOR_STAKING_OPS = 100 ether;
    if (targetAmountToStake > amountStaked) {
      uint256 amountToStake = targetAmountToStake - amountStaked;
      if (amountToStake >= MINIMUM_AMOUNT_FOR_STAKING_OPS) {
        require(
          amountToStake < address(this).balance,
          "Strategy does not have enough native tokens to add to stake: NOT_ENOUGH_TO_STAKE"
        );
        delegate(targetValidator, amountToStake);
        _afterDelegate(amountToStake);
      }
    }
    if (targetAmountToStake < amountStaked) {
      uint256 amountToUnstake = amountStaked - targetAmountToStake;
      if (amountToUnstake >= MINIMUM_AMOUNT_FOR_STAKING_OPS) {
        require(
          amountToUnstake < amountStaked,
          "Stake does not have enough of a balance to undelegate: NOT_ENOUGH_TO_STAKE"
        );
        undelegate(targetValidator, amountToUnstake);
        _afterUndelegate(amountToUnstake);
      }
    }
    return true;
  }

  function _afterDelegate(uint256 amountToStake) internal {
    amountStaked += amountToStake;
    amountDeposited = amountStaked + address(this).balance + pendingUndelegation;
  }

  function _afterUndelegate(uint256 amountToUnstake) internal {
    pendingUndelegation = amountToUnstake;
    amountStaked -= amountToUnstake;
    amountDeposited = amountStaked + address(this).balance + pendingUndelegation;
  }

  function getTargetStakeAmount() internal view returns (uint256) {
    uint256 currentAllocation = (checkAllocation() * 2) + 1;
    require(
      currentAllocation <= 100,
      "Allocation for LP and Redeem exceeds 49.5%: ALLOCATION_TOO_HIGH"
    );
    return (upController.getNativeBalance() * (100 - currentAllocation)) / 100;
  }

  ///@notice The withdrawAll function should withdraw all native tokens, including rewards as native tokens, and send them to the UP Controller.
  ///@return bool value will be false if undelegation is required first and is successful, value will be true if there is there is nothing to undelegate. All balance will be sen

  function withdrawAll() external virtual override onlyAdmin whenNotPaused returns (bool) {
    if (amountStaked > 10000000000000000000) {
      undelegate(targetValidator, amountStaked);
      uint256 currentEpoch = epoch();
      _afterUndelegateAll(currentEpoch);
      return false;
    }
    _drainStrategyBalance();
    return true;
  }

  function _afterUndelegateAll(uint256 currentEpoch) internal {
    epochOfLastRebalance = currentEpoch;
    pendingUndelegation = amountStaked;
    amountStaked = 0;
  }

  function _drainStrategyBalance() internal {
    uint256 amountSent = address(this).balance;
    (bool successTransfer, ) = address(upController).call{value: amountSent}("");
    require(successTransfer, "FAIL_SENDING_NATIVE");
    amountDeposited -= amountSent;
  }

  ///@notice The gather function should claim all yield earned from the native tokens while leaving the amount deposited intact.
  ///Then, this function should send all earnings to the rebalancer contract. This function MUST only send native tokens to the rebalancer.
  ///For example, if the tokens are deposited in a lending protocol, it should the totalBalance minus the amountDeposited.

  function gather() public virtual override onlyRebalancer whenNotPaused {
    uint256 currentEpoch = epoch();
    require(
      currentEpoch > epochOfLastRebalance + 8,
      "Seven epoches have not passed since last rebalance"
    );
    lastClaimedAmount = rewardsAmount();
    collectRewards();
    _afterGather(currentEpoch);
  }

  function _afterGather(uint256 currentEpoch) internal {
    (bool successTransfer, ) = address(msg.sender).call{value: lastClaimedAmount}("");
    timestampOfLastClaim = block.timestamp;
    require(successTransfer, "FAIL_SENDING_NATIVE");
    epochOfLastRebalance = currentEpoch;
    pendingUndelegation = 0;
    emit GatherCalled();
  }

  function setUPController(address newAddress) public onlyAdmin {
    upController = UPController(payable(newAddress));
    emit UpdateUPController(newAddress);
  }

  function setRebalancer(address newAddress) public onlyAdmin {
    rebalancer = Rebalancer(payable(newAddress));
    emit UpdateRebalancer(newAddress);
  }

  function setValidator(address newAddress) public onlyAdmin {
    targetValidator = newAddress;
    emit UpdateValidator(newAddress);
  }
}
