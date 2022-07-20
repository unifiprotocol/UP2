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

contract AAVEStrategy is Strategy, AccessControl, Pausable {
  bytes32 public constant REBALANCER_ROLE = keccak256("REBALANCER_ROLE");
  uint256 public amountDeposited = 0;
  address public wrappedTokenAddress; 
  address public aaveIncentivesController;
  address public aavePool;
  address public wethGateway;
  address public aaveDataProvider;
  address public aaveDepositToken;

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "AAVEStrategy: ONLY_ADMIN");
    _;
  }

  modifier onlyRebalancer() {
    require(hasRole(REBALANCER_ROLE, msg.sender), "AAVEStrategy: ONLY_REBALANCER");
    _;
  }

  event UpdateRebalancer(address _rebalancer);

  ///@param _wrappedTokenAddress The Wrapped Native Asset, for example, WONE if deploying on Harmony.
  ///@param _aaveIncentivesController AAVE's Native Controller - typically 0x929EC64c34a17401F460460D4B9390518E5B473e on all chains.
  ///@param _aavePool AAVE's Pool - typically 0x794a61358D6845594F94dc1DB02A252b5b4814aD on all chains.
  ///@param _wethGateway AAVE's Wrapped Native Token Gateway - varies by chain.
  ///@param _aaveDataProvider AAVE's Pool Data Provider - typically 0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654 on all chains.
  ///@param _aaveDepositToken AAVE's aToken for the deposited wrapped address  - typically 0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97 on all chains.

  constructor(    
    address _wrappedTokenAddress,
    address _aaveIncentivesController,
    address _aavePool,
    address _wethGateway,
    address _aaveDataProvider,
    address _aaveDepositToken) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(REBALANCER_ROLE, msg.sender);
    wrappedTokenAddress = _wrappedTokenAddress;
    aaveIncentivesController = _aaveIncentivesController;
    aavePool = _aavePool;
    wethGateway = _wethGateway;
    aaveDataProvider = _aaveDataProvider;
    aaveDepositToken = _aaveDepositToken;
  }


  /// Read Functions

  ///@notice Checks the total amount of incentives earned by this address, excluding interest.
  function checkRewardsBalance() public view returns (uint256 rewardsBalance) {
    address[] memory asset = new address[](1);
    asset[0] = address(aaveDepositToken);
    rewardsBalance = IAaveIncentivesController(aaveIncentivesController).getUserRewards(asset, address(this), wrappedTokenAddress);
    return (rewardsBalance);
  }

  ///@notice Checks amonut of assets sent to AAVE by this address.
  function checkAAVEBalance() public view returns (uint256 aaveBalance) {
    (uint256 aaveBalanceData,,,,,,,,) = IDataProvider(aaveDataProvider).getUserReserveData(wrappedTokenAddress, address(this));
    aaveBalance = aaveBalanceData;
    return aaveBalance;
  }

  ///@notice Checks the amount of interest earned by the lending pool, excluding incentives.
  function checkAAVEInterest() public view returns (uint256 aaveEarnings) {
      uint256 aaveBalance = checkAAVEBalance();
      aaveEarnings = aaveBalance - amountDeposited;
      return aaveEarnings;
  }

    ///@notice Checks Total Amount Earned by AAVE deposit above deposited total.
  function checkUnclaimedEarnings() public view returns (uint256 unclaimedEarnings) {
    uint256 aaveEarnings = checkAAVEInterest();
    uint256 rewardsBalance = checkRewardsBalance();
    unclaimedEarnings = aaveEarnings + rewardsBalance;
    return unclaimedEarnings;
  }

     ///@notice Returns Amount of Native Tokens Earned since last rebalance
  function checkRewards() public view override returns (IStrategy.Rewards memory) {
    uint256 unclaimedEarnings = checkUnclaimedEarnings();
    return IStrategy.Rewards(
      unclaimedEarnings,
      amountDeposited,
      block.timestamp
    );
  }

  /// Write Functions

  ///@notice Claims AAVE Incentive Rewards earned by this address.
  function _claimAAVERewards() internal returns (uint256 aaveClaimed) {
    address[] memory asset = new address[](1);
    asset[0] = address(aaveDepositToken);
    uint256 rewardsBalance = IAaveIncentivesController(aaveIncentivesController).getUserRewards(asset, address(this), wrappedTokenAddress);
    uint256 rewardsClaimed = IAaveIncentivesController(aaveIncentivesController).claimRewards(asset, rewardsBalance, address(this), wrappedTokenAddress);
    IWETH(wrappedTokenAddress).withdraw(rewardsClaimed);
    return (rewardsClaimed);
  }

  ///@notice Withdraws Interest from Token Deposits from AAVE. 
  function _withdrawAAVEInterest() internal returns (uint256 yieldEarned) {
    yieldEarned = checkAAVEInterest();
    IERC20(aaveDepositToken).approve(wethGateway, yieldEarned);
    IWETHGateway(wethGateway).withdrawETH(aavePool, yieldEarned, address(this));
    return (yieldEarned);
  }

  ///@notice Withdraws an amount from Token Deposits from AAVE
  function withdraw(uint256 amount) public override whenNotPaused onlyRebalancer returns (bool) {
    require(amount <= amountDeposited, "AAVEStrategy: Amount Requested to Withdraw is Greater Than Amount Deposited");
    IERC20(aaveDepositToken).approve(wethGateway, amount);
    IWETHGateway(wethGateway).withdrawETH(aavePool, amount, address(this));
    (bool successTransfer, ) = address(msg.sender).call{value: amount}("");
    require(successTransfer, "AAVEStrategy: FAIL_SENDING_NATIVE");
    amountDeposited -= amount;
    return successTransfer;
  }

  ///@notice Withdraws all funds from AAVE, as well as claims & unwraps token rewards
   function withdrawAll() public override whenNotPaused onlyRebalancer returns (bool) {
    _claimAAVERewards();
    uint256 aaveBalance = checkAAVEBalance();
    IERC20(aaveDepositToken).approve(wethGateway, aaveBalance);
    IWETHGateway(wethGateway).withdrawETH(aavePool, aaveBalance, address(this));
    (bool successTransfer, ) = address(msg.sender).call{value: address(this).balance}("");
    require(successTransfer);
    amountDeposited = 0;
    return successTransfer;
  }

   ///@notice Deposits native tokens to AAVE.
  function deposit(uint256 depositValue) public whenNotPaused onlyRebalancer override payable returns (bool) {
    require(depositValue == msg.value, "AAVEStrategy: Deposit Value Parameter does not equal payable amount");
    IWETHGateway(wethGateway).depositETH{value: depositValue}(aavePool, address(this), 0);
    amountDeposited += depositValue;
    return true;
  }

  ///@notice Claims Rewards + Withdraws All Tokens on AAVE, and sends to Controller
  function gather() public override whenNotPaused onlyRebalancer {
    uint256 rewardsClaimed = _claimAAVERewards();
    uint256 yieldEarned = _withdrawAAVEInterest();
    uint256 totalEarned = rewardsClaimed + yieldEarned;
    (bool successTransfer, ) = address(msg.sender).call{value: totalEarned}("");
    require(successTransfer);
  }

  ///Admin Functions

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
    require(_aaveIncentivesController != address(0), "AAVEStrategy: INVALID_ADDRESS");
    aaveIncentivesController = _aaveIncentivesController;
  }

  ///@notice Permissioned function to update the address of the aavePool
  ///@param _aavePool - the address of the new aavePool
  function updateaavePool(address _aavePool) public onlyAdmin {
    require(_aavePool != address(0), "AAVEStrategy: INVALID_ADDRESS");
    aavePool = _aavePool;
  }

  ///@notice Permissioned function to update the address of the wethGateway
  ///@param _wethGateway - the address of the new wethGateway
  function updatewethGateway(address _wethGateway) public onlyAdmin {
    require(_wethGateway != address(0), "AAVEStrategy: INVALID_ADDRESS");
    wethGateway = _wethGateway;
  }

  ///@notice Permissioned function to update the address of the aaveDataProvider
  ///@param _aaveDataProvider - the address of the new aaveDataProvider
  function updateaaveDataProvider(address _aaveDataProvider) public onlyAdmin{
    require(_aaveDataProvider != address(0), "AAVEStrategy: INVALID_ADDRESS");
    aaveDataProvider = _aaveDataProvider;
  }

  ///@notice Permissioned function to update the address of the aaveDepositToken
  ///@param _aaveDepositToken - the address of the new aaveDepositToken
  function updateaaveDepositToken(address _aaveDepositToken) public onlyAdmin {
    require(_aaveDepositToken != address(0), "AAVEStrategy: INVALID_ADDRESS");
    aaveDepositToken = _aaveDepositToken;
  }
}
