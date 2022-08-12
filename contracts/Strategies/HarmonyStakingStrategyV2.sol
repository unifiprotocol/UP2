// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IStrategy.sol";
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

contract Strategy is IStrategy, Safe, AccessControl, Pausable, StakingPrecompiles {
  bytes32 public constant REBALANCER_ROLE = keccak256("REBALANCER_ROLE");

  /// @notice The amountDeposited MUST reflect the amount of native tokens currently deposited into other contracts. All deposits and withdraws so update this variable.
  uint256 public amountDeposited = 0;
  uint256 public epochOfLastRebalance = 0;
  uint256 public lastClaimedAmount = 0;
  address public targetValidator;

  UPController public upController;
  Rebalancer public rebalancer;

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ONLY_ADMIN");
    _;
  }

  modifier onlyRebalancer() {
    require(hasRole(REBALANCER_ROLE, msg.sender), "ONLY_REBALANCER");
    _;
  }

  event UpdateRebalancer(address _rebalancer);

  constructor(
    address _fundsTarget,
    address _targetValidator,
    address _upController,
    address _rebalancer
  ) Safe(_fundsTarget) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(REBALANCER_ROLE, msg.sender);
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
    IStrategy.Rewards memory result = IStrategy.Rewards(
      lastClaimedAmount,
      amountDeposited,
      block.timestamp
    );
    return result;
  }

  // Write Functions

  function acceptMoney() public payable {}

  function deposit(uint256 depositValue)
    public
    payable
    override
    onlyRebalancer
    whenNotPaused
    returns (bool)
  {
    require(depositValue == msg.value, "Deposit Value Parameter does not equal payable amount");
    acceptMoney();
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

  ///@notice The deposit function should receive native tokens and then deposit them into your strategy.
  ///For example, if your strategy is depositing native tokens into a lending protocol, the deposit function should contain all the logic to transfer tokens into the lending protocol.
  ///In addition, the depositValue should be updated to reflect the tokens deposited into your strategy.
  ///@param depositValue If using native tokens, the parameter should equal the payable amount of the function. This is kept as a parameter in the case a strategy is utilized that does not use native tokens. You will receive an unused parameter warning.

  //   function deposit(uint256 depositValue)
  //     public
  //     payable
  //     override
  //     onlyRebalancer
  //     whenNotPaused
  //     returns (bool)
  //   {
  //     require(depositValue == msg.value, "Deposit Value Parameter does not equal payable amount");
  //     uint256 currentAllocation = checkAllocation() * 2;
  //     require(currentAllocation <= 100, "Allocation for LP and Redeem exceeds 50%");
  //     uint256 targetAmountToStake = (upController.getNativeBalance() * (100 - currentAllocation)) /
  //       100;
  //     if (targetAmountToStake > amountDeposited) {
  //       uint256 amountToStake = targetAmountToStake - amountDeposited;
  //       require(
  //         amountToStake > address(this).balance,
  //         "Strategy does not have enough native tokens to add to stake"
  //       );
  //       uint256 amountDelegated = delegate(targetValidator, amountToStake);
  //       amountDeposited += amountDelegated;
  //     }
  //     if (targetAmountToStake < amountDeposited) {
  //       uint256 amountToUnstake = targetAmountToStake - amountDeposited;
  //       require(
  //         amountToUnstake > amountDeposited,
  //         "Stake does not have enough of a balance to undelegate"
  //       );
  //       uint256 amountUnDelegated = undelegate(targetValidator, amountToUnstake);
  //       amountDeposited -= amountUnDelegated;
  //     }
  //     return true;
  //   }

  ///@notice The withdraw function should withdraw an amount from your strategy and send them to the rebalancer.
  ///For example, if using a lending protocol, this function should withdraw tokens from the strategy, and send them to the rebalancer.
  ///In addition, the depositValue should be updated to reflect the tokens withdrawn into your strategy. UP requires all tokens returned to the balancer be in native token format.
  ///@param withdrawAmount This is the amount of native tokens that is to be withdrawn from the strategy.

  //   function withdraw(uint256 withdrawAmount)
  //     public
  //     override
  //     onlyRebalancer
  //     whenNotPaused
  //     returns (bool)
  //   {
  //     require(
  //       withdrawAmount <= address(this).balance,
  //       "Amount Requested to Withdraw is Greater Than Currently Available in Wallet"
  //     );
  //     uint256 currentAllocation = checkAllocation() * 2;
  //     require(currentAllocation <= 100, "Allocation for LP and Redeem exceeds 50%");
  //     uint256 targetAmountToStake = (upController.getNativeBalance() * (100 - currentAllocation)) /
  //       100;
  //     // This needs to undelegate the maximum amount versus requiring
  //     (bool successTransfer, ) = address(msg.sender).call{value: withdrawAmount}("");
  //     require(successTransfer, "FAIL_SENDING_NATIVE");
  //     if (targetAmountToStake > amountDeposited) {
  //       uint256 amountToStake = targetAmountToStake - amountDeposited;
  //       require(
  //         amountToStake > address(this).balance,
  //         "Strategy does not have enough native tokens to add to stake"
  //       );
  //       uint256 amountDelegated = delegate(targetValidator, amountToStake);
  //       amountDeposited += amountDelegated;
  //     }
  //     if (targetAmountToStake < amountDeposited) {
  //       uint256 amountToUnstake = targetAmountToStake - amountDeposited;
  //       require(
  //         amountToUnstake > amountDeposited,
  //         "Stake does not have enough of a balance to undelegate"
  //       );
  //       uint256 amountUnDelegated = undelegate(targetValidator, amountToUnstake);
  //       amountDeposited -= amountUnDelegated;
  //     }
  //     return true;
  //   }

  ///@notice The withdrawAll function should withdraw all native tokens, including rewards as native tokens, and send them to the rebalancer.

  function withdrawAll() external virtual override onlyRebalancer whenNotPaused returns (bool) {
    // Check if any native tokens are still delegated
    // If so, undelegate
    // Check if amountDeposited < 1
    // If not, undelegate. Return message that native tokens are still being undelegated. Rebalance must occur after undelegation funds are received.
    (bool successTransfer, ) = address(msg.sender).call{value: address(this).balance}("");
    require(successTransfer, "FAIL_SENDING_NATIVE");
    return true;
  }

  ///@notice The gather function should claim all yield earned from the native tokens while leaving the amount deposited intact.
  ///Then, this function should send all earnings to the rebalancer contract. This function MUST only send native tokens to the rebalancer.
  ///For example, if the tokens are deposited in a lending protocol, it should the totalBalance minus the amountDeposited.

  function gather() public virtual override onlyRebalancer whenNotPaused {
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

  function delegate(address validatorAddress, uint256 amount)
    public
    override
    onlyAdmin
    returns (uint256 result)
  {
    super.delegate(validatorAddress, amount);
  }

  function withdrawFunds() public onlyAdmin returns (bool) {
    return _withdrawFunds();
  }

  function withdrawFundsERC20(address tokenAddress) public onlyAdmin returns (bool) {
    return _withdrawFundsERC20(tokenAddress);
  }
}
