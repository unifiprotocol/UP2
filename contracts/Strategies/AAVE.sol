// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Strategy.sol";
import "./Interfaces/ILendingPool.sol";
import "./Interfaces/IWETHGateway.sol";
import "./Interfaces/IAaveIncentivesController.sol";
import "../Helpers/Safe.sol";


/// @title Staking Contract for UP to interact with AAVE
/// @author dxffffff & A Fistful of Stray Cat Hair
/// @notice This controller deposits the native tokens backing UP into the AAVE Supply Pool, and triggers the Rebalancer

contract AAVE is AccessControl, Safe {
  bytes32 public constant INVOKER_ROLE = keccak256("INVOKER_ROLE");
  bytes32 public constant REBALANCER_ROLE = keccak256("INVOKER_ROLE");
  address public rebalancer = address(0);
  uint256 public amountDeposited = 0;
  address public wrappedTokenAddress = 0xcF664087a5bB0237a0BAd6742852ec6c8d69A27a; //WONE Address
  address public aaveIncentivesController = 0x929EC64c34a17401F460460D4B9390518E5B473e; //AAVE Harmony Incentives Controller
  address public aavePool = 0x794a61358D6845594F94dc1DB02A252b5b4814aD; //AAVE Harmony Lending Pool
  address public wethGateway = 0xe86B52cE2e4068AdE71510352807597408998a69; //AAVE Harmony WETH Gateway
  address public aaveDepositToken = 0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97;

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ONLY_ADMIN");
    _;
  }

  modifier onlyInvoker() {
    require(hasRole(INVOKER_ROLE, msg.sender), "ONLY_INVOKER");
    _;
  }

  modifier onlyRebalancer() {
    require(hasRole(REBALANCER_ROLE, msg.sender), "ONLY_REBALANCER");
    _;
  }

  event UpdateRebalancer(address _rebalancer);
  event TriggerRebalance(uint256 amountClaimed);

  constructor(address _rebalancer, address _wrappedTokenAddress, address _aaveIncentivesController, address _aavePool, address _wethGateway, address _aaveDepositToken) {
    rebalancer = _rebalancer;
    wrappedTokenAddress = _wrappedTokenAddress;
    aaveIncentivesController = _aaveIncentivesController;
    aavePool = _aavePool;
    wethGateway = _wethGateway;
    aaveDepositToken = _aaveDepositToken;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(INVOKER_ROLE, msg.sender);
    _setupRole(REBALANCER_ROLE, msg.sender);
  }

  /// Read Functions

  ///@notice Checks the total amount of rewards earned by this address.
  function checkRewardsBalance() public view returns (uint256 rewardsBalance) {
    address[] memory asset = new address[](1);
    asset[0] = address(wrappedTokenAddress);
    rewardsBalance = IAaveIncentivesController(aaveIncentivesController).getUserRewards(asset, address(this), wrappedTokenAddress);
    return (rewardsBalance);
  }

  ///@notice Alternative? 
  // function checkUnclaimedRewards() public returns (uint256 unclaimedRewards) {
  //   unclaimedRewards = IAaveIncentivesController(aaveIncentivesController).getUserUnclaimedRewards(address(this));
  //   return (unclaimedRewards);
  // }

  ///@notice Checks amonut of assets to AAVe by this address.
  function checkAAVEBalance() public view returns (uint256 aaveBalance) {
    (uint256 aaveBalanceData,,,,,) = ILendingPool(aavePool).getUserAccountData(address(this));
    aaveBalance = aaveBalanceData;
    return (aaveBalance);
  }

  ///@notice Checks Total Amount Earned by AAVE deposit above deposited total.
  function checkUnclaimedEarnings() public view returns (uint256 unclaimedEarnings) {
    (uint256 aaveBalance) = checkAAVEBalance();
    uint256 aaveEarnings = aaveBalance - amountDeposited;
    (uint256 rewardsBalance) = checkRewardsBalance();
    unclaimedEarnings = aaveEarnings + rewardsBalance;
    return (unclaimedEarnings);
  }

  /// Write Functions

  function initialApprove() public onlyInvoker {
    IERC20(aaveDepositToken).approve(wethGateway, 0);
  }

  ///@notice Claims AAVE Incentive Rewards earned by this address.
  function claimAAVERewards() internal returns (uint256 rewardsClaimed) {
    address[] memory asset = new address[](1);
    asset[0] = address(wrappedTokenAddress);
    uint256 rewardsBalance = IAaveIncentivesController(aaveIncentivesController).getUserRewards(asset, address(this), wrappedTokenAddress);
    rewardsClaimed = IAaveIncentivesController(aaveIncentivesController).claimRewards(asset, rewardsBalance, address(this), wrappedTokenAddress);
    return (rewardsBalance);
  }

  ///@notice Withdraws All Deposits within AAVE. 
  function withdrawAAVE() internal {
    (uint256 aaveBalance) = checkAAVEBalance();
    uint256 lpBalance = IERC20(aaveDepositToken).balanceOf(address(this));
    IERC20(aaveDepositToken).approve(wethGateway, lpBalance);
    IWETHGateway(wethGateway).withdrawETH(aavePool, aaveBalance, address(this));
    amountDeposited = 0;
  }

  function depositAAVE() public payable onlyRebalancer {
    uint256 depositValue = msg.value;
    IWETHGateway(wethGateway).depositETH{value: depositValue}(aavePool, address(this), 0);
    amountDeposited = depositValue;
  }


  // function deposit() public onlyRebalancer - deposit to AAVE - send transaction to AAVE pool, updates amountDeposited variable //
  //fallback is Deposit AAVE
  /// function triggerRebalance() - claim rewards over amount deposited - checks total amount on AAVE, subtracts amountDeposited, sends gas refund to msg.sender, sends amount earned to Rebalancer to begin rebalance. Will emit event on amonut earned.


  
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
