// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Strategy.sol";
import "./Interfaces/ILendingPool.sol";
import "./Interfaces/IWETHGateway.sol";
import "./Interfaces/IAaveIncentivesController.sol";
import "../Helpers/Safe.sol";

/// @title Staking Contract for UP to interact with AAVE
/// @author dxffffff & A Fistful of Stray Cat Hair
/// @notice This controller deposits the native tokens backing UP into the AAVE Supply Pool, and triggers the Rebalancer

contract AAVEHarmonyTest is AccessControl, Safe, Pausable {
  bytes32 public constant REBALANCER_ROLE = keccak256("REBALANCER_ROLE");
  uint256 public amountDeposited = 0;
  address public wrappedTokenAddress = 0x3e4b51076d7e9B844B92F8c6377087f9cf8C8696; //WONE Test Net Address
  address public aaveIncentivesController = 0xC05FAA52459226aA19eDF47DD858Ff137D41Ce84; //AAVE Harmony Testnet Proxy Incentives Controller
  address public aavePool = 0x85C1F3f1bB439180f7Bfda9DFD61De82e10bD554; //AAVE Harmony Testnet Proxy Lending Pool
  address public wethGateway = 0xdDc3C9B8614092e6188A86450c8D597509893E20; //AAVE Harmony Test WETH Gateway
  address public aaveDepositToken = 0xA6a1ec235B90e0b5567521F52e5418B9BA189334; /// AAVE Harmony Test WONE AToken

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
    rewardsBalance = IAaveIncentivesController(aaveIncentivesController).getUserRewards(
      asset,
      address(this),
      wrappedTokenAddress
    );
    return (rewardsBalance);
  }

  ///@notice Alternative?
  // function checkUnclaimedRewards() public returns (uint256 unclaimedRewards) {
  //   unclaimedRewards = IAaveIncentivesController(aaveIncentivesController).getUserUnclaimedRewards(address(this));
  //   return (unclaimedRewards);
  // }

  ///@notice Checks amonut of assets to AAVe by this address.
  function checkAAVEBalance() public view returns (uint256 aaveBalance) {
    (uint256 aaveBalanceData, , , , , ) = ILendingPool(aavePool).getUserAccountData(address(this));
    aaveBalance = aaveBalanceData;
    return (aaveBalance);
  }

  ///@notice Checks Total Amount Earned by AAVE deposit above deposited total.
  function checkUnclaimedEarnings() public view returns (uint256 unclaimedEarnings) {
    uint256 aaveBalance = checkAAVEBalance();
    uint256 aaveEarnings = aaveBalance - amountDeposited;
    uint256 rewardsBalance = checkRewardsBalance();
    unclaimedEarnings = aaveEarnings + rewardsBalance;
    return (unclaimedEarnings);
  }

  /// Write Functions

  ///@notice Claims AAVE Incentive Rewards earned by this address.
  function claimAAVERewards() public onlyRebalancer {
    address[] memory asset = new address[](1);
    asset[0] = address(wrappedTokenAddress);
    uint256 rewardsBalance = IAaveIncentivesController(aaveIncentivesController).getUserRewards(
      asset,
      address(this),
      wrappedTokenAddress
    );
    IAaveIncentivesController(aaveIncentivesController).claimRewards(
      asset,
      rewardsBalance,
      address(this),
      wrappedTokenAddress
    );
  }

  ///@notice Withdraws All Native Token Deposits from AAVE.
  function withdrawAAVE() public onlyRebalancer {
    uint256 aaveBalance = checkAAVEBalance();
    uint256 lpBalance = IERC20(aaveDepositToken).balanceOf(address(this));
    IERC20(aaveDepositToken).approve(wethGateway, lpBalance);
    IWETHGateway(wethGateway).withdrawETH(aavePool, aaveBalance, address(this));
    amountDeposited = 0;
  }

  ///@notice Deposits native tokens to AAVE. (CHANGE TO DEPOSIT)
  function depositAAVE() public payable onlyRebalancer {
    uint256 depositValue = msg.value;
    IWETHGateway(wethGateway).depositETH{value: depositValue}(aavePool, address(this), 0);
    amountDeposited += depositValue;
  }

  ///@notice Claims Rewards + Withdraws All Tokens on AAVE, and sends to Controller
  function gather() public onlyRebalancer {
    uint256 earnings = checkUnclaimedEarnings();
    claimAAVERewards();
    withdrawAAVE();
    (bool successTransfer, ) = address(msg.sender).call{value: address(this).balance}("");
    emit amountEarned(earnings);
  }

  receive() external payable {}

  ///Admin Functions
  function withdrawFunds(address target) public onlyAdmin returns (bool) {
    return _withdrawFunds(target);
  }

  function withdrawFundsERC20(address target, address tokenAddress)
    public
    onlyAdmin
    returns (bool)
  {
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
