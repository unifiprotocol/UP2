// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Strategy.sol";
import "./Interfaces/IWETHGateway.sol";
import "./Interfaces/IDataProvider.sol";

/// @title Staking Contract for UP to interact with AAVE
/// @author dxffffff & A Fistful of Stray Cat Hair
/// @notice This controller deposits the native tokens backing UP into the AAVE Supply Pool, and triggers the Rebalancer

contract AAVEStrategy is Strategy {
  address public wrappedTokenAddress;
  address public aavePool;
  address public wethGateway;
  address public aaveDataProvider;
  address public aaveDepositToken;

  event UpdateRebalancer(address _rebalancer);

  ///@param _wrappedTokenAddress The Wrapped Native Asset, for example, WONE if deploying on Harmony.
  ///@param _aavePool AAVE's Pool - typically 0x794a61358D6845594F94dc1DB02A252b5b4814aD on all chains.
  ///@param _wethGateway AAVE's Wrapped Native Token Gateway - varies by chain.
  ///@param _aaveDataProvider AAVE's Pool Data Provider - typically 0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654 on all chains.
  ///@param _aaveDepositToken AAVE's aToken for the deposited wrapped address  - typically 0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97 on all chains.

  constructor(
    address _wrappedTokenAddress,
    address _aavePool,
    address _wethGateway,
    address _aaveDataProvider,
    address _aaveDepositToken,
    address _fundsTarget
  ) Strategy(_fundsTarget) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(REBALANCER_ROLE, msg.sender);
    wrappedTokenAddress = _wrappedTokenAddress;
    aavePool = _aavePool;
    wethGateway = _wethGateway;
    aaveDataProvider = _aaveDataProvider;
    aaveDepositToken = _aaveDepositToken;
  }

  /// Read Functions

  ///@notice Checks current balance of assets on AAVE
  function checkAAVEBalance() public view returns (uint256 aaveBalance) {
    (uint256 aaveBalanceData, , , , , , , , ) = IDataProvider(aaveDataProvider).getUserReserveData(
      wrappedTokenAddress,
      address(this)
    );
    aaveBalance = aaveBalanceData;
    return aaveBalance;
  }

  ///@notice Checks the amount of interest earned by the lending pool
  function checkAAVEInterest() public view returns (uint256 aaveEarnings) {
    uint256 aaveBalance = checkAAVEBalance();
    aaveEarnings = aaveBalance - amountDeposited;
    return aaveEarnings;
  }

  ///@notice Returns Amount of Native Tokens Earned since last rebalance
  function checkRewards() public view override returns (IStrategy.Rewards memory) {
    uint256 unclaimedEarnings = checkAAVEInterest();
    return IStrategy.Rewards(unclaimedEarnings, amountDeposited, block.timestamp);
  }

  /// Write Functions

  ///@notice Withdraws Interest from Token Deposits from AAVE.
  function _withdrawAAVEInterest() internal returns (uint256 yieldEarned) {
    yieldEarned = checkAAVEInterest();
    IERC20(aaveDepositToken).approve(wethGateway, yieldEarned); // Is safe, slightly over amount required for approval. Saves gas to not compute deposit token to redeem value due to gateway.
    IWETHGateway(wethGateway).withdrawETH(aavePool, yieldEarned, address(this));
    return (yieldEarned);
  }

  ///@notice Withdraws an amount from Token Deposits from AAVE
  function withdraw(uint256 amount) public override whenNotPaused onlyRebalancer returns (bool) {
    require(amount <= amountDeposited, "AAVEStrategy: WITHDRAW_GREATER_THAN_AMOUNT_DEPOSITED");
    IERC20(aaveDepositToken).approve(wethGateway, amount);
    IWETHGateway(wethGateway).withdrawETH(aavePool, amount, address(this));
    (bool successTransfer, ) = address(msg.sender).call{value: amount}("");
    require(successTransfer, "AAVEStrategy: FAIL_SENDING_NATIVE");
    amountDeposited -= amount;
    return successTransfer;
  }

  ///@notice Withdraws all funds from AAVE, as well as claims & unwraps token rewards
  function withdrawAll() public override whenNotPaused onlyRebalancer returns (bool) {
    uint256 aaveBalance = checkAAVEBalance();
    uint256 fundingTokenBalance = IERC20(aaveDepositToken).balanceOf(address(this));
    IERC20(aaveDepositToken).approve(wethGateway, fundingTokenBalance);
    IWETHGateway(wethGateway).withdrawETH(aavePool, aaveBalance, address(this));
    (bool successTransfer, ) = address(msg.sender).call{value: address(this).balance}("");
    require(successTransfer);
    amountDeposited = 0;
    return successTransfer;
  }

  ///@notice Deposits native tokens to AAVE.
  function deposit(uint256 depositValue)
    public
    payable
    override
    whenNotPaused
    onlyRebalancer
    returns (bool)
  {
    require(depositValue == msg.value, "AAVEStrategy: DEPOSIT_VALUE_DOES_NOT_EQUAL_PAYABLE_AMOUNT");
    IWETHGateway(wethGateway).depositETH{value: depositValue}(aavePool, address(this), 0);
    amountDeposited += depositValue;
    return true;
  }

  ///@notice Claims Interest on AAVE and sends to controller
  function gather() public override whenNotPaused onlyRebalancer {
    _withdrawAAVEInterest();
    (bool successTransfer, ) = address(msg.sender).call{value: address(this).balance}("");
    require(successTransfer);
  }

  ///Admin Functions

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
  function updateaaveDataProvider(address _aaveDataProvider) public onlyAdmin {
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
