// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vendor is ReentrancyGuard, Pausable, Ownable {
  using SafeERC20 for IERC20;

  address OLD_UP = address(0);
  address UP = address(0);

  constructor(address oldUp, address newUp) {
    OLD_UP = oldUp;
    UP = newUp;
  }

  function swap(uint256 _amount) public nonReentrant whenNotPaused {
    require(_amount > 0, "INVALID_AMOUNT");
    IERC20 oldUp = IERC20(OLD_UP);
    oldUp.safeTransferFrom(msg.sender, address(this), _amount);

    IERC20 up = IERC20(UP);
    up.safeTransferFrom(address(this), msg.sender, _amount);
  }

  function balance() public view returns (uint256) {
    return IERC20(UP).balanceOf(address(this));
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _pause();
  }
}
