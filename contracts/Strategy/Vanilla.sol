// SPDX-License-Identifier: MIT

import "./IStrategy.sol";

pragma solidity ^0.8.4;

contract Vanilla is IStrategy {
  receive() external payable {}

  function deposit(uint256 amount) external returns (bool) {}

  function withdraw(uint256 amount) external returns (bool) {}

  function gather() public {
    (bool successTransfer, ) = address(msg.sender).call{value: address(this).balance}("");
    require(successTransfer, "FAIL_SENDING_NATIVE");
  }
}
