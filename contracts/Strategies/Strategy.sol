// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IStrategy.sol";
import "../Helpers/Safe.sol";

abstract contract Strategy is IStrategy, Safe {
  mapping(address => bool) public owners;
  uint256 public amountDeposited = 0;

  modifier onlyOwner() {
    require(owners[msg.sender], "Strategy: ONLY_OWNER");
    _;
  }

  constructor() {
    owners[msg.sender] = true;
  }

  receive() external payable virtual {}

  function deposit(uint256 amount) external payable virtual override returns (bool) {
    amountDeposited += amount;
    return true;
  }

  function withdraw(uint256 amount) external virtual override returns (bool) {
    amountDeposited -= amount;
    (bool successTransfer, ) = address(msg.sender).call{value: amount}("");
    require(successTransfer, "Strategy: FAIL_SENDING_NATIVE");
    return true;
  }

  function withdrawAll() external virtual override returns (bool) {
    amountDeposited -= address(this).balance > amountDeposited
      ? address(this).balance
      : amountDeposited - address(this).balance;
    (bool successTransfer, ) = address(msg.sender).call{value: address(this).balance}("");
    require(successTransfer, "Strategy: FAIL_SENDING_NATIVE");
    return true;
  }

  function gather() public virtual override {
    uint256 nativeAmount = address(this).balance - amountDeposited;
    (bool successTransfer, ) = address(msg.sender).call{value: nativeAmount}("");
    require(successTransfer, "Strategy: FAIL_SENDING_NATIVE");
  }

  function checkRewards() public view virtual override returns (IStrategy.Rewards memory) {
    uint256 rewards = address(this).balance - amountDeposited;
    IStrategy.Rewards memory result = IStrategy.Rewards(
      rewards,
      amountDeposited,
      block.timestamp * 1000
    );
    return result;
  }

  function addOwner(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    owners[_newOwner] = true;
  }

  function removeOwner(address _owner) public onlyOwner {
    owners[_owner] = false;
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
