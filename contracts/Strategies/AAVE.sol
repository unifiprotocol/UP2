// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Strategy.sol";

/// @title Staking Contract for UP to interact with AAVE
/// @author dxffffff & A Fistful of Stray Cat Hair
/// @notice This controller deposits the native tokens backing UP into the AAVE Supply Pool, and triggers the Rebalancer

contract AAVE is Strategy {
  address public rebalancer = address(0);
  uint256 public amountDeposited = 0;

  event UpdateRebalancer(address _rebalancer);
  event TriggerRebalance(uint256 amountClaimed);

  constructor(address _rebalancer) {
    rebalancer = _rebalancer;
  }

  // function deposit() - deposit to AAVE - send transaction to AAVE pool, updates amountDeposited variable

  // function triggerRebalance() - claim rewards over amount deposited - checks total amount on AAVE, subtracts amountDeposited, sends gas refund to msg.sender, sends amount earned to Rebalancer to begin rebalance. Will emit event on amonut earned.
  
  // function withdrawAAVE() -

  // function claimWrappedRewardsAAVE() -
  
  ///@notice Permissioned function to update the address of the Rebalancer
  ///@param _rebalancer - the address of the new rebalancer
  function updateRebalancer(address _rebalancer) public {
    require(_rebalancer != address(0), "INVALID_ADDRESS");
    rebalancer = _rebalancer;
    emit UpdateRebalancer(_rebalancer);
  }

  // function deposit(uint256 amount) external returns (bool) {
  //   return true;
  // }

  // function withdraw(uint256 amount) external returns (bool) {
  //   (bool successTransfer, ) = address(msg.sender).call{value: amount}("");
  //   require(successTransfer, "FAIL_SENDING_NATIVE");
  //   return true;
  // }

  // function gather() public {
  //   (bool successTransfer, ) = address(msg.sender).call{value: address(this).balance}("");
  //   require(successTransfer, "FAIL_SENDING_NATIVE");
  // }
}
