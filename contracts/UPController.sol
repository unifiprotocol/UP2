// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./UP.sol";
import "./Helpers/Safe.sol";
import "hardhat/console.sol";

contract UPController is AccessControl, Safe, Pausable, ReentrancyGuard {
  bytes32 public constant REBALANCER_ROLE = keccak256("REBALANCER_ROLE");

  address public UP_TOKEN = address(0);
  uint256 public nativeBorrowed = 0;
  uint256 public upBorrowed = 0;
  // uint256 public mintRate = 0;

  event PremiumMint(address indexed _from, uint256 _amount, uint256 _price, uint256 _value);
  event SyntheticMint(address _from, uint256 _amount, uint256 _newUpBorrowed);
  event BorrowNative(address _from, uint256 _amount, uint256 _newNativeBorrowed);
  event NewMintRate(uint256 _newMintRate);
  event Repay(uint256 _nativeAmount, uint256 _upAmount);
  event Redeem(uint256 _upAmount, uint256 _redeemAmount);

  modifier onlyRebalancer() {
    require(hasRole(REBALANCER_ROLE, msg.sender), "ONLY_REBALANCER");
    _;
  }

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ONLY_ADMIN");
    _;
  }

  constructor(address _UP) {
    require(_UP != address(0), "Invalid UP address");
    UP_TOKEN = _UP;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    // setMintRate(_mintRate);
  }

  fallback() external payable {}

  receive() external payable {}

  function getVirtualPrice() public view returns (uint256) {
    if (getNativeBalance() == 0) return 0;
    return ((getNativeBalance() * 1e18) / (UP(UP_TOKEN).totalSupply() - upBorrowed));
  }

  // function getVirtualMintPrice(uint256 _depositedAmount) public view returns (uint256) {
  //   if (getNativeBalance() - _depositedAmount == 0) return 0;
  //   return (((getNativeBalance() - _depositedAmount) * 1e18) /
  //     (UP(UP_TOKEN).totalSupply() - upBorrowed));
  // }

  function getNativeBalance() public view returns (uint256) {
    return address(this).balance + nativeBorrowed;
  }

  function actualTotalSupply() public view returns (uint256) {
    return UP(UP_TOKEN).totalSupply() - upBorrowed;
  }

  function borrowNative(uint256 _borrowAmount, address _to) public onlyRebalancer {
    require(address(this).balance >= _borrowAmount, "NOT_ENOUGH_BALANCE");
    (bool success, ) = _to.call{value: _borrowAmount}("");
    nativeBorrowed += _borrowAmount;
    require(success, "BORROW_NATIVE_FAILED");
    emit BorrowNative(_to, _borrowAmount, nativeBorrowed);
  }

  function borrowUP(uint256 _borrowAmount, address _to) public onlyRebalancer {
    upBorrowed += _borrowAmount;
    UP(UP_TOKEN).mint(_to, _borrowAmount);
    emit SyntheticMint(msg.sender, _borrowAmount, upBorrowed);
  }

  function mintSyntheticUP(uint256 _mintAmount, address _to) public onlyRebalancer {
    borrowUP(_mintAmount, _to);
  }

  function repay(uint256 upAmount) public payable onlyRebalancer {
    require(upAmount <= upBorrowed, "UP_AMOUNT_GT_BORROWED");
    require(msg.value <= nativeBorrowed, "NATIVE_AMOUNT_GT_BORROWED");
    UP(UP_TOKEN).transferFrom(msg.sender, address(this), upAmount);
    upBorrowed -= upAmount;
    nativeBorrowed -= msg.value;
    emit Repay(msg.value, upAmount);
  }

  function redeem(uint256 upAmount) public onlyRebalancer {
    require(upAmount > 0, "AMOUNT_EQ_0");
    uint256 redeemAmount = (getVirtualPrice() * upAmount) / 1e18;
    (bool success, ) = msg.sender.call{value: redeemAmount}("");
    require(success, "REDEEM_FAILED");
    emit Redeem(upAmount, redeemAmount);
  }

  /**
   * @dev Mints UP token at premium rates (virtualPrice - PREMIUM_RATE_%).
   */
  // function mintUP() public payable nonReentrant whenNotPaused {
  //   require(msg.value > 0, "INVALID_PAYABLE_AMOUNT");
  //   uint256 currentPrice = getVirtualMintPrice(msg.value);
  //   if (currentPrice == 0) return;
  //   uint256 discountedAmount = msg.value - ((msg.value * (mintRate * 100)) / 10000);
  //   uint256 mintAmount = (discountedAmount * currentPrice) / 1e18;
  //   UP(UP_TOKEN).mint(msg.sender, mintAmount);
  //   emit PremiumMint(msg.sender, mintAmount, currentPrice, msg.value);
  // }

  // /**
  //  * @param _mintRate - mint rate in percent texrms, _mintRate = 5 = 5%.
  //  */
  // function setMintRate(uint256 _mintRate) public onlyOwner {
  //   require(_mintRate <= 100, "MINT_RATE_GT_100");
  //   mintRate = _mintRate;
  //   emit NewMintRate(_mintRate);
  // }

  function pause() public onlyAdmin {
    _pause();
  }

  function unpause() public onlyAdmin {
    _unpause();
  }

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
}
