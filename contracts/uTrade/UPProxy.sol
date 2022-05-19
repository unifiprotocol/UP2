// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../UP.sol";
import "../UPController.sol";
import "../Helpers/Safe.sol";

contract UPProxy is Proxy, Ownable, Safe {
  address public UP_TOKEN;
  address public UP_CONTROLLER;

  constructor(address _UP, address _UP_CONTROLLER) {
    UP_TOKEN = _UP;
    UP_CONTROLLER = _UP_CONTROLLER;
  }

  receive() external payable override {
    (bool success, ) = address(UP_CONTROLLER).call{value: address(this).balance}("");
    require(success, "FAIL_RECEIVING_NATIVE");
  }

  function mint(address to, uint256 value) public payable returns (bool) {
    UP(UP_TOKEN).mint(to, value);
    (bool successTransfer, ) = address(UP_CONTROLLER).call{value: address(this).balance}("");
    require(successTransfer, "FAIL_SENDING_NATIVE");
    return true;
  }

  function _implementation() internal view override returns (address) {
    return UP_TOKEN;
  }

  function setController(address newAddress) public onlyOwner {
    UP_CONTROLLER = newAddress;
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
