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
  bytes32 public constant REBALANCER_ROLE = keccak256("REBALANCER_ROLE");
  uint256 public amountDeposited = 0;
  address public wrappedTokenAddress = address(0); 
  address public aaveIncentivesController = address(0); 
  address public aavePool = address(0); 
  address public wethGateway = address(0);
  address public aaveDepositToken = address(0);

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ONLY_ADMIN");
    _;
  }

  modifier onlyRebalancer() {
    require(hasRole(REBALANCER_ROLE, msg.sender), "ONLY_REBALANCER");
    _;
  }

  event amountEarned(uint256 earnings);
  event UpdateRebalancer(address _rebalancer);

  constructor(address _wrappedTokenAddress, address _aaveIncentivesController, address _aavePool, address _wethGateway, address _aaveDepositToken) {
    wrappedTokenAddress = _wrappedTokenAddress;
    aaveIncentivesController = _aaveIncentivesController;
    aavePool = _aavePool;
    wethGateway = _wethGateway;
    aaveDepositToken = _aaveDepositToken;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
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

  ///@notice Claims AAVE Incentive Rewards earned by this address.
  function _claimAAVERewards() internal {
    address[] memory asset = new address[](1);
    asset[0] = address(wrappedTokenAddress);
    uint256 rewardsBalance = IAaveIncentivesController(aaveIncentivesController).getUserRewards(asset, address(this), wrappedTokenAddress);
    IAaveIncentivesController(aaveIncentivesController).claimRewards(asset, rewardsBalance, address(this), wrappedTokenAddress);
  }

  ///@notice Withdraws All Native Token Deposits from AAVE. 
  function _withdrawAAVE() internal {
    (uint256 aaveBalance) = checkAAVEBalance();
    uint256 lpBalance = IERC20(aaveDepositToken).balanceOf(address(this));
    IERC20(aaveDepositToken).approve(wethGateway, lpBalance);
    IWETHGateway(wethGateway).withdrawETH(aavePool, aaveBalance, address(this));
    amountDeposited = 0;
  }

   ///@notice Deposits native tokens to AAVE.
  function depositAAVE() public payable onlyRebalancer {
    uint256 depositValue = msg.value;
    IWETHGateway(wethGateway).depositETH{value: depositValue}(aavePool, address(this), 0);
    amountDeposited += depositValue;
  }

  ///@notice Claims Rewards + Withdraws All Tokens on AAVE, and sends to Controller
  function gather() public onlyRebalancer {
    uint256 earnings = checkUnclaimedEarnings();
    _claimAAVERewards();
    _withdrawAAVE();
    (bool successTransfer, ) = address(msg.sender).call{value: address(this).balance}("");
    emit amountEarned(earnings);
  }

  receive() external payable {
    depositAAVE();
    }
}
