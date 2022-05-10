// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./UP.sol";
import "./Helpers/Safe.sol";

contract UPController is Ownable, Safe, Pausable, ReentrancyGuard {
  address public UP_TOKEN = address(0);
  uint256 public nativeBorrowed = 0;
  uint256 public upBorrowed = 0;
  uint256 public mintRate = 0;

  event PremiumMint(address indexed _from, uint256 _amount, uint256 _price, uint256 _value);
  event SyntheticMint(address _from, uint256 _amount, uint256 _newUpBorrowed);
  event BorrowNative(address _from, uint256 _amount, uint256 _newNativeBorrowed);
  event NewMintRate(uint256 _newMintRate);
  event Repay(uint256 _nativeAmount, uint256 _upAmount);

  constructor(address _UP, uint256 _mintRate) {
    require(_UP != address(0), "Invalid UP address");
    UP_TOKEN = _UP;
    setMintRate(_mintRate);
  }

  fallback() external payable {}

  receive() external payable {}

  function getVirtualPrice() public view returns (uint256) {
    return getNativeBalance() / (UP(UP_TOKEN).totalSupply() - upBorrowed);
  }

  function getNativeBalance() public view returns (uint256) {
    return address(this).balance + nativeBorrowed;
  }

  function actualTotalSupply() public view returns (uint256) {
    return UP(UP_TOKEN).totalSupply() - upBorrowed;
  }

  function borrowNative(uint256 _borrowAmount, address _to) public onlyOwner returns (bool) {
    require(address(this).balance >= _borrowAmount, "NOT_ENOUGH_BALANCE");
    nativeBorrowed += _borrowAmount;
    (bool success, ) = _to.call{value: _borrowAmount}("");
    require(success, "BORROW_NATIVE_FAILED");
    emit BorrowNative(_to, _borrowAmount, nativeBorrowed);
    return success;
  }

  function borrowUP(uint256 _borrowAmount, address _to) public onlyOwner returns (bool) {
    upBorrowed += _borrowAmount;
    UP(UP_TOKEN).mint(_to, _borrowAmount);
    emit SyntheticMint(msg.sender, _borrowAmount, upBorrowed);
    return true;
  }

  // TODO: ARE THE SAME?????

  function mintSyntheticUP(uint256 _mintAmount) public onlyOwner returns (bool) {
    upBorrowed += _mintAmount;
    UP(UP_TOKEN).mint(msg.sender, _mintAmount);
    emit SyntheticMint(msg.sender, _mintAmount, upBorrowed);
    return true;
  }

  function repay(uint256 upAmount) public payable onlyOwner {
    require(upAmount <= upBorrowed, "UP_AMOUNT_GT_UP_BORROWED");
    require(msg.value <= nativeBorrowed, "UP_AMOUNT_GT_UP_BORROWED");
    UP(UP_TOKEN).transferFrom(msg.sender, address(this), upAmount);
    upBorrowed -= upAmount;
    nativeBorrowed -= msg.value;
    emit Repay(msg.value, upAmount);
  }

  /**
   * @dev Mints UP token at premium rates (virtualPrice - PREMIUM_RATE_%).
   */
  function mintUP() public payable nonReentrant whenNotPaused returns (bool) {
    require(msg.value > 0, "INVALID_PAYABLE_AMOUNT");
    // TODO: VERY CAREFUL! DECIMALS CAN MESS EVERYTHING ASFGASFGHJAJS, BUT IT SHOULDN'T 🥲
    // TODO: SHOULD I GET THE PRICE FROM THE VIRTUAL PRICE OR FROM THE LP!?
    uint256 currentPrice = getVirtualPrice();
    uint256 mintAmount = (msg.value * currentPrice) - (currentPrice * (mintRate / 100));
    UP(UP_TOKEN).mint(msg.sender, mintAmount);
    emit PremiumMint(msg.sender, mintAmount, currentPrice, msg.value);
    return true;
  }

  /**
   * @param _mintRate - mint rate in percent terms, _mintRate = 5 = 5%.
   */
  function setMintRate(uint256 _mintRate) public onlyOwner {
    require(_mintRate <= 100, "MINT_RATE_GT_100");
    mintRate = _mintRate;
    emit NewMintRate(_mintRate);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _pause();
  }

  function withdrawFunds(address target) public onlyOwner returns (bool) {
    return _withdrawFunds(target);
  }

  function withdrawFundsERC20(address target, address tokenAddress)
    public
    onlyOwner
    returns (bool)
  {
    return _withdrawFundsERC20(target, tokenAddress);
  }
}
