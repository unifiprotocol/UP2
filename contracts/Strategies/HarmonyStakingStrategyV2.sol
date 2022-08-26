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
  address public targetValidator;
  address public monitor;

  UPController public upController;
  Rebalancer public rebalancer;

  modifier onlyMonitor() {
    require(hasRole(MONITOR_ROLE, msg.sender), "ONLY_MONITOR");
    _;
  }

  event UpdateRebalancer(address _rebalancer);
  event UpdateUPController(address _upController);

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

  function checkAllocation() public view virtual returns (uint256 allocationOthers) {
    uint256 allocations = rebalancer.allocationLP() + rebalancer.allocationRedeem();
    return allocations;
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
    uint256 depositedAmount = amountStaked + address(this).balance;
    IStrategy.Rewards memory result = IStrategy.Rewards(
      lastClaimedAmount,
      depositedAmount,
      block.timestamp
    );
    return result;
  }

  // Write Functions

  function deposit(uint256 depositValue)
    public
    payable
    override
    onlyRebalancer
    whenNotPaused
    returns (bool)
  {
    require(depositValue == msg.value, "Deposit Value Parameter does not equal payable amount");
    return true;
  }

  function withdraw(uint256 withdrawAmount)
    public
    override
    onlyRebalancer
    whenNotPaused
    returns (bool)
  {
    require(
      withdrawAmount <= address(this).balance,
      "Amount Requested to Withdraw is Greater Than Currently Available in Wallet"
    );
    (bool successTransfer, ) = address(msg.sender).call{value: withdrawAmount}("");
    require(successTransfer, "FAIL_SENDING_NATIVE");
    return true;
  }

  function adjustDelegation() public onlyMonitor whenNotPaused returns (bool) {
    uint256 currentAllocation = checkAllocation() * 2;
    require(currentAllocation <= 100, "Allocation for LP and Redeem exceeds 50%");
    uint256 targetAmountToStake = (upController.getNativeBalance() * (100 - currentAllocation)) /
      100;
    require(
      targetAmountToStake > 100000000000000000000,
      "Harmony Delegate and Undelegate must be greater than 100 ONE"
    );
    if (targetAmountToStake > amountStaked) {
      uint256 amountToStake = targetAmountToStake - amountStaked;
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

  ///@notice The withdrawAll function should withdraw all native tokens, including rewards as native tokens, and send them to the UP Controller.
  ///@return bool value will be false if undelegation is required first and is successful, value will be true if there is there is nothing to undelegate. All balance will be sen

  function withdrawAll() external virtual override onlyAdmin whenNotPaused returns (bool) {
    if (amountStaked > 10000000000000000000) {
      undelegate(targetValidator, amountStaked);
      uint256 currentEpoch = epoch();
      epochOfLastRebalance = currentEpoch;
      return false;
    }
    (bool successTransfer, ) = address(upController).call{value: address(this).balance}("");
    require(successTransfer, "FAIL_SENDING_NATIVE");
    return true;
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
    uint256 balanceBefore = address(this).balance;
    collectRewards();
    uint256 balanceAfter = address(this).balance;
    uint256 claimedRewards = balanceAfter - balanceBefore;
    lastClaimedAmount = claimedRewards;
    (bool successTransfer, ) = address(msg.sender).call{value: claimedRewards}("");
    require(successTransfer, "FAIL_SENDING_NATIVE");
    epochOfLastRebalance = currentEpoch;
    emit gatherCalled();
  }

  function setUPController(address newAddress) public onlyAdmin {
    upController = UPController(payable(newAddress));
    emit UpdateUPController(newAddress);
  }

  function setRebalancer(address newAddress) public onlyAdmin {
    rebalancer = Rebalancer(payable(newAddress));
    emit UpdateRebalancer(newAddress);
  }
}
