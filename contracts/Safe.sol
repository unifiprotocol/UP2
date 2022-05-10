// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract Safe {
  using SafeERC20 for IERC20;

  function _withdrawFunds(address target) internal returns (bool) {
    (bool sent, ) = address(target).call{value: address(this).balance}("");
    require(sent, "Failed to send Ether");
    return sent;
  }

  function _withdrawFundsERC20(address target, address tokenAddress) internal returns (bool) {
    IERC20 token = IERC20(tokenAddress);
    token.safeTransferFrom(address(this), target, token.balanceOf(address(this)));
    return true;
  }
}
