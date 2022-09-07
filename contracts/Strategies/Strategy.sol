// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IStrategy.sol";
import "../Helpers/Safe.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// Contract Strategy must use our customized Safe.sol and OpenZeppelin's AccessControl and Pauseable Contracts.
// Safe.sol is utilized so the DAO can retrieve any lost assets within the Strategy Contract.
// AccessControl.sol is utilized so only the Rebalancer can interact with the strategy, and only the DAO can update the Rebalancer Contract.
// Pausable.sol is utilized so that DAO can pause the strategy in an emergency.

contract Strategy is IStrategy, Safe, AccessControl, Pausable {
  bytes32 public constant REBALANCER_ROLE = keccak256("REBALANCER_ROLE");

  /// @notice The amountDeposited MUST reflect the amount of native tokens currently deposited into other contracts. All deposits and withdraws so update this variable.
  uint256 public amountDeposited = 0;

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Strategy: ONLY_ADMIN");
    _;
  }

  modifier onlyRebalancer() {
    require(hasRole(REBALANCER_ROLE, msg.sender), "Strategy: ONLY_REBALANCER");
    _;
  }

  constructor(address _fundsTarget) Safe(_fundsTarget) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  receive() external payable virtual {}

  event GatherCalled();

  // Read Functions

  ///@notice The public checkRewards function MUST return a struct with the amount of pending rewards valued in native tokens, the total amount deposited, and the block timestamp.
  ///For example, if 500 NativeTokens are deposited, and the strategy has earned 5 Native Tokens and 2 of TokenA,
  ///the function should calculate the return for selling 2 TokenA, and add to the 5 Native Tokens.
  ///If we assume that each TokenA is worth 4 native tokens, then the unclaimedEarnings value should return a value of 13, adjusted for percision.

  function checkRewards() public view virtual override returns (IStrategy.Rewards memory) {
    uint256 rewards = address(this).balance - amountDeposited;
    IStrategy.Rewards memory result = IStrategy.Rewards(
      rewards,
      amountDeposited,
      block.timestamp * 1000
    );
    return result;
  }

  // Write Functions

  ///@notice The deposit function should receive native tokens and then deposit them into your strategy.
  ///For example, if your strategy is depositing native tokens into a lending protocol, the deposit function should contain all the logic to transfer tokens into the lending protocol.
  ///In addition, the depositValue should be updated to reflect the tokens deposited into your strategy.
  ///@param depositValue If using native tokens, the parameter should equal the payable amount of the function. This is kept as a parameter in the case a strategy is utilized that does not use native tokens. You will receive an unused parameter warning.

  function deposit(uint256 depositValue)
    public
    payable
    virtual
    override
    onlyRebalancer
    whenNotPaused
    returns (bool)
  {
    require(
      depositValue == msg.value,
      "Strategy: Deposit Value Parameter does not equal payable amount"
    );
    //Work your magic here - Code the logic to earn yield!
    amountDeposited += depositValue;
    return true;
  }

  ///@notice The withdraw function should withdraw an amount from your strategy and send them to the rebalancer.
  ///For example, if using a lending protocol, this function should withdraw tokens from the strategy, and send them to the rebalancer.
  ///In addition, the depositValue should be updated to reflect the tokens withdrawn into your strategy. UP requires all tokens returned to the balancer be in native token format.
  ///@param amount This is the amount of native tokens that is to be withdrawn from the strategy.

  function withdraw(uint256 amount)
    public
    virtual
    override
    onlyRebalancer
    whenNotPaused
    returns (bool)
  {
    require(
      amount <= amountDeposited,
      "Strategy: Amount Requested to Withdraw is Greater Than Amount Deposited"
    );
    //Work your magic here - Code the logic to withdraw and send the requested amount of native tokens here!
    (bool successTransfer, ) = address(msg.sender).call{value: amount}("");
    require(successTransfer, "Strategy: FAIL_SENDING_NATIVE");
    amountDeposited -= amount;
    return successTransfer;
  }

  ///@notice The withdrawAll function should withdraw all native tokens, including rewards as native tokens, and send them to the rebalancer.

  function withdrawAll() external virtual override onlyRebalancer whenNotPaused returns (bool) {
    //Get all those tokens here - code the logic to withdraw all here!
    uint256 balance = address(this).balance;
    (bool successTransfer, ) = address(msg.sender).call{value: balance}("");
    require(successTransfer, "Strategy: FAIL_SENDING_NATIVE");
    amountDeposited -= balance;
    return true;
  }

  ///@notice The gather function should claim all yield earned from the native tokens while leaving the amount deposited intact.
  ///Then, this function should send all earnings to the rebalancer contract. This function MUST only send native tokens to the rebalancer.
  ///For example, if the tokens are deposited in a lending protocol, it should the totalBalance minus the amountDeposited.

  function gather() public virtual override onlyRebalancer whenNotPaused {
    //Claim all those rewards here
    uint256 nativeAmount = address(this).balance - amountDeposited;
    (bool successTransfer, ) = address(msg.sender).call{value: nativeAmount}("");
    require(successTransfer, "Strategy: FAIL_SENDING_NATIVE");
    emit GatherCalled();
  }

  function withdrawFunds() public onlyAdmin returns (bool) {
    return _withdrawFunds();
  }

  function withdrawFundsERC20(address tokenAddress) public onlyAdmin returns (bool) {
    return _withdrawFundsERC20(tokenAddress);
  }
}
