// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Strategy.sol";
import "./Interfaces/ILendingPool.sol";
// import "./Interfaces/IWETHGateway.sol";
import "./Interfaces/IAaveIncentivesController.sol";

/// @title Staking Contract for UP to interact with AAVE
/// @author dxffffff & A Fistful of Stray Cat Hair
/// @notice This controller deposits the native tokens backing UP into the AAVE Supply Pool, and triggers the Rebalancer

contract AAVE is Strategy {
  address public rebalancer = address(0);
  uint256 public amountDeposited = 0;
  address public wrappedTokenAddress = 0xcF664087a5bB0237a0BAd6742852ec6c8d69A27a; //WONE Address
  address public aaveIncentivesController = 0x929EC64c34a17401F460460D4B9390518E5B473e; //AAVE Harmony Incentives Controller
  address public aavePool = 0x794a61358D6845594F94dc1DB02A252b5b4814aD; //AAVE Harmony Lending Pool

  event UpdateRebalancer(address _rebalancer);
  event TriggerRebalance(uint256 amountClaimed);

  constructor(address _rebalancer, address _wrappedTokenAddress, address _aaveIncentivesController, address _aavePool) {
    rebalancer = _rebalancer;
    wrappedTokenAddress = _wrappedTokenAddress;
    aaveIncentivesController = _aaveIncentivesController;
    aavePool = _aavePool;
  }

  /// Read Functions

  ///@notice Checks the total amount of rewards earned by this address.
  function checkRewardsBalance() public returns (uint256 rewardsBalance) {
    address[] memory asset = new address[](1);
    asset[0] = address(wrappedTokenAddress);
    rewardsBalance = IAaveIncentivesController(aaveIncentivesController).getUserRewards(asset, address(this), wrappedTokenAddress);
    return (rewardsBalance);
  }

  ///@notice Checks amonut of deposited assets to AAVe by this address.
  function checkAAVEBalance() public returns (uint256 aaveBalance) {
    (uint256 aaveBalanceData,,,,,) = ILendingPool(aavePool).getUserAccountData(address(this));
    aaveBalance = aaveBalanceData;
    return (aaveBalance);
  }

  ///@notice Checks Total Amount Earned by AAVE deposit above deposited total.
  function checkUnclaimedEarnings() public returns (uint256 unclaimedEarnings) {
    (uint256 aaveBalance) = checkAAVEBalance();
    uint256 aaveEarnings = aaveBalance - amountDeposited;
    (uint256 rewardsBalance) = checkRewardsBalance();
    uint256 unclaimedEarnings = aaveEarnings + rewardsBalance;
    return (unclaimedEarnings);
  }

  /// Write Functions

  ///@notice Claims AAVE Incentive Rewards earned by this address.
  function claimAAVERewards() internal returns (uint256 rewardsClaimed) {
    address[] memory asset = new address[](1);
    asset[0] = address(wrappedTokenAddress);
    uint256 rewardsBalance = IAaveIncentivesController(aaveIncentivesController).getUserRewards(asset, address(this), wrappedTokenAddress);
    rewardsClaimed = IAaveIncentivesController(aaveIncentivesController).claimRewards(asset, rewardsBalance, address(this), wrappedTokenAddress);
    return (rewardsBalance);
  }

  // function checkUnclaimedRewards() public returns (uint256 unclaimedRewards) {
  //   unclaimedRewards = IAaveIncentivesController(aaveIncentivesController).getUserUnclaimedRewards(address(this));
  //   return (unclaimedRewards);
  // }


  // function deposit() public onlyRebalancer - deposit to AAVE - send transaction to AAVE pool, updates amountDeposited variable //

  /// function triggerRebalance() - claim rewards over amount deposited - checks total amount on AAVE, subtracts amountDeposited, sends gas refund to msg.sender, sends amount earned to Rebalancer to begin rebalance. Will emit event on amonut earned.
  
  /// function withdrawAAVE() -


  
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
