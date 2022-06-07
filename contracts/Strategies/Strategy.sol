// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IStrategy.sol";
import "../Helpers/Safe.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Strategy is IStrategy, Safe, Ownable {
  receive() external payable virtual {}

  function deposit(uint256 amount) external payable override returns (bool) {
    return true;
  }

  function withdraw(uint256 amount) external override returns (bool) {
    (bool successTransfer, ) = address(msg.sender).call{value: amount}("");
    require(successTransfer, "FAIL_SENDING_NATIVE");
    return true;
  }

  function withdrawAll() external override returns (bool) {
    (bool successTransfer, ) = address(msg.sender).call{value: address(this).balance}("");
    require(successTransfer, "FAIL_SENDING_NATIVE");
    return true;
  }

  function gather() public override {
    uint256 nativeAmount = address(this).balance;
    (bool successTransfer, ) = address(msg.sender).call{value: nativeAmount}("");
    require(successTransfer, "FAIL_SENDING_NATIVE");
  }

  function getRewards() public view returns (IStrategy.Rewards memory) {
    uint256 nativeAmount = address(this).balance;
    IStrategy.Rewards memory result = IStrategy.Rewards(
      nativeAmount,
      nativeAmount,
      block.timestamp
    );
    return result;
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
