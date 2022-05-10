// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./UP.sol";
import "./Safe.sol";

contract UPController is Ownable, Safe {
  address public UP_TOKEN = address(0);
  uint256 public nativeBorrowed = 0;
  uint256 public upBorrowed = 0;
  uint256 public mintRate = 5;

  constructor(address _UP) {
    require(_UP != address(0), "Invalid UP address");
    UP_TOKEN = _UP;
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
    return success;
  }

  function borrowUP(uint256 _borrowAmount, address _to) public onlyOwner returns (bool) {
    upBorrowed += _borrowAmount;
    UP(UP_TOKEN).mint(_to, _borrowAmount);
    return true;
  }

  function repay(uint256 upAmount) public payable onlyOwner {
    require(upAmount <= upBorrowed, "UP_AMOUNT_GT_UP_BORROWED");
    require(msg.value <= nativeBorrowed, "UP_AMOUNT_GT_UP_BORROWED");
    UP(UP_TOKEN).transferFrom(msg.sender, address(this), upAmount);
    upBorrowed -= upAmount;
    nativeBorrowed -= msg.value;
  }

  function mintSyntheticUP(uint256 _mintAmount) public onlyOwner returns (bool) {
    upBorrowed += _mintAmount;
    UP(UP_TOKEN).mint(msg.sender, _mintAmount);
    return true;
  }

  /**
   * @dev Mints UP token at premium rates (virtualPrice - PREMIUM_RATE_%).
   */
  function mintUP() public payable returns (bool) {
    require(msg.value > 0, "INVALID_PAYABLE_AMOUNT");
    // TODO: VERY CAREFUL! DECIMALS CAN MESS EVERYTHING ASFGASFGHJAJS, BUT IT SHOULDN'T 🥲
    // TODO: SHOULD I GET THE PRICE FROM THE VIRTUAL PRICE OR FROM THE LP!?
    uint256 mintAmount = (msg.value * getVirtualPrice()) - (getVirtualPrice() * (mintRate / 100));
    UP(UP_TOKEN).mint(msg.sender, mintAmount);
    return true;
  }

  /**
   * @param _mintRate - mint rate in percent terms, _mintRate = 5 = 5%.
   */
  function setMintRate(uint256 _mintRate) public onlyOwner {
    require(_mintRate >= 0);
    require(_mintRate <= 100);
    mintRate = _mintRate;
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
