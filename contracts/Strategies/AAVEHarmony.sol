// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Strategy.sol";
import "./Interfaces/ILendingPool.sol";
import "./Interfaces/IWETH.sol";
import "./Interfaces/IWETHGateway.sol";
import "./Interfaces/IAaveIncentivesController.sol";
import "./Interfaces/IDataProvider.sol";
import "../Helpers/Safe.sol";


/// @title Staking Contract for UP to interact with AAVE
/// @author dxffffff & A Fistful of Stray Cat Hair
/// @notice This controller deposits the native tokens backing UP into the AAVE Supply Pool, and triggers the Rebalancer

contract AAVEHarmony is AccessControl, Pausable, Safe {
  bytes32 public constant REBALANCER_ROLE = keccak256("REBALANCER_ROLE");
  uint256 public amountDeposited = 0;
  address public wrappedTokenAddress = 0xcF664087a5bB0237a0BAd6742852ec6c8d69A27a; //WONE Address
  address public aaveIncentivesController = 0x929EC64c34a17401F460460D4B9390518E5B473e; //AAVE Harmony Incentives Controller
  address public aavePool = 0x794a61358D6845594F94dc1DB02A252b5b4814aD; //AAVE Harmony Lending Pool
  address public wethGateway = 0xe86B52cE2e4068AdE71510352807597408998a69; //AAVE Harmony WETH Gateway
  address public aaveDataProvider = 0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654; //AAVE Harmony Data Provider
  address public aaveDepositToken = 0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97; /// AAVE WONE AToken

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

  constructor() {
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

  ///@notice Checks amonut of assets to AAVe by this address.
  function checkAAVEBalance() public view returns (uint256 aaveBalance) {
    (uint256 aaveBalanceData,,,,,,,,) = IDataProvider(aaveDataProvider).getUserReserveData(wrappedTokenAddress, address(this));
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
  function claimAAVERewards() public returns (uint256 aaveClaimed) {
    address[] memory asset = new address[](1);
    asset[0] = address(wrappedTokenAddress);
    uint256 rewardsBalance = IAaveIncentivesController(aaveIncentivesController).getUserRewards(asset, address(this), wrappedTokenAddress);
    uint256 rewardsClaimed = IAaveIncentivesController(aaveIncentivesController).claimRewards(asset, rewardsBalance, address(this), wrappedTokenAddress);
    IWETH(wrappedTokenAddress).withdraw(rewardsClaimed);
    return (rewardsClaimed);
  }

  ///@notice Withdraws All Native Token Deposits from AAVE. 
  function withdrawAAVE() public returns (uint256 yieldEarned) {
    uint256 aaveBalance = checkAAVEBalance();
    uint256 yieldEarned = aaveBalance - amountDeposited;
    IERC20(aaveDepositToken).approve(wethGateway, aaveBalance);
    IWETHGateway(wethGateway).withdrawETH(aavePool, aaveBalance, address(this));
    amountDeposited = 0;
    return (yieldEarned);
  }

   ///@notice Deposits native tokens to AAVE. (CHANGE TO DEPOSIT)
  function deposit() public payable {
    uint256 depositValue = msg.value;
    IWETHGateway(wethGateway).depositETH{value: depositValue}(aavePool, address(this), 0);
    amountDeposited += depositValue;
  }

  ///@notice Claims Rewards + Withdraws All Tokens on AAVE, and sends to Controller
  function gather() public returns (IStrategy.Rewards memory) {
    uint256 depositedAmount = amountDeposited;
    uint256 rewardsClaimed = claimAAVERewards();
    uint256 yieldEarned = withdrawAAVE();
    uint256 totalEarned = rewardsClaimed + yieldEarned;
    (bool successTransfer, ) = address(msg.sender).call{value: address(this).balance}("");
    IStrategy.Rewards memory result = IStrategy.Rewards(
      totalEarned,
      depositedAmount,
      block.timestamp
    );
    emit amountEarned(totalEarned);
    return (result);
  }
  //Return struct with earnings, staked, timestamp upon gather function//
  receive() external payable {
    }
  
  ///Admin Functions
    function withdrawFunds(address target) public onlyAdmin returns (bool) {
        return _withdrawFunds(target);
    }
    
    function withdrawFundsERC20(address target, address tokenAddress) public onlyAdmin returns (bool) {
        return _withdrawFundsERC20(target, tokenAddress);
    }

  /// @notice Permissioned function to pause UPaddress Controller
  function pause() public onlyAdmin {
    _pause();
  }

  /// @notice Permissioned function to unpause UPaddress Controller
  function unpause() public onlyAdmin {
    _unpause();
  }

  ///@notice Permissioned function to update the address of the Aave Incentives Controller
  ///@param _aaveIncentivesController - the address of the new Aave Incentives Controller
  function updateaaveIncentivesController(address _aaveIncentivesController) public onlyAdmin {
    require(_aaveIncentivesController != address(0), "INVALID_ADDRESS");
    aaveIncentivesController = _aaveIncentivesController;
  }

  ///@notice Permissioned function to update the address of the aavePool
  ///@param _aavePool - the address of the new aavePool
  function updateaavePool(address _aavePool) public onlyAdmin {
    require(_aavePool != address(0), "INVALID_ADDRESS");
    aavePool = _aavePool;
  }

  ///@notice Permissioned function to update the address of the wethGateway
  ///@param _wethGateway - the address of the new wethGateway
  function updatewethGateway(address _wethGateway) public onlyAdmin {
    require(_wethGateway != address(0), "INVALID_ADDRESS");
    wethGateway = _wethGateway;
  }

  ///@notice Permissioned function to update the address of the aaveDepositToken
  ///@param _aaveDepositToken - the address of the new aaveDepositToken
  function updateaaveDepositToken(address _aaveDepositToken) public onlyAdmin {
    require(_aaveDepositToken != address(0), "INVALID_ADDRESS");
    aaveDepositToken = _aaveDepositToken;
  }
}
