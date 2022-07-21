// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IStrategy.sol";
import "../Helpers/Safe.sol";

abstract contract Strategy is IStrategy, Safe {
  mapping(address => bool) public owners;

  modifier onlyOwner() {
    require(owners[msg.sender], "Strategy: ONLY_OWNER");
    _;
  }

  constructor(address _fundsTarget) Safe(_fundsTarget) {
    owners[msg.sender] = true;
  }

  receive() external payable virtual {}

  function deposit(uint256 amount) external virtual payable override returns (bool) {
    return true;
  }

  function withdraw(uint256 amount) external virtual override returns (bool) {
    (bool successTransfer, ) = address(msg.sender).call{value: amount}("");
    require(successTransfer, "Strategy: FAIL_SENDING_NATIVE");
    return true;
  }

  function withdrawAll() external virtual override returns (bool) {
    (bool successTransfer, ) = address(msg.sender).call{value: address(this).balance}("");
    require(successTransfer, "Strategy: FAIL_SENDING_NATIVE");
    return true;
  }

  function gather() public virtual override {
    uint256 nativeAmount = address(this).balance;
    (bool successTransfer, ) = address(msg.sender).call{value: nativeAmount}("");
    require(successTransfer, "Strategy: FAIL_SENDING_NATIVE");
  }

  function checkRewards() public virtual override view returns (IStrategy.Rewards memory) {
    uint256 nativeAmount = address(this).balance;
    IStrategy.Rewards memory result = IStrategy.Rewards(
      nativeAmount,
      nativeAmount,
      block.timestamp
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

  function withdrawFunds() public onlyOwner returns (bool) {
    return _withdrawFunds();
  }

  function withdrawFundsERC20(address tokenAddress)
    public
    onlyOwner
    returns (bool)
  {
    return _withdrawFundsERC20(tokenAddress);
  }
}
