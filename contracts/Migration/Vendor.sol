// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../Helpers/Safe.sol";

/// @title Vendor
/// @author dxffffff & A Fistful of Stray Cat Hair
/// @notice Swaps 1:1 between UP tokens - Needs to be top up first.

contract Vendor is ReentrancyGuard, Pausable, Ownable, Safe {
  using SafeERC20 for IERC20;

  address public OLD_UP = address(0);
  address public UP = address(0);

  event Swap(address _from, uint256 _amount);

  constructor(address oldUp, address newUp) {
    OLD_UP = oldUp;
    UP = newUp;
  }

  /// @notice Giving an amount of tokens, will swap between them
  /// @param _amount Amount to be swapped
  function swap(uint256 _amount) public nonReentrant whenNotPaused {
    require(_amount > 0, "Vendor: INVALID_AMOUNT");
    IERC20 oldUp = IERC20(OLD_UP);
    oldUp.safeTransferFrom(msg.sender, address(this), _amount);

    IERC20 up = IERC20(UP);
    up.safeTransfer(msg.sender, _amount);

    emit Swap(msg.sender, _amount);
  }

  function balance() public view returns (uint256) {
    return IERC20(UP).balanceOf(address(this));
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function withdrawFundsERC20(address target, address tokenAddress)
    public
    onlyOwner
    returns (bool)
  {
    return _withdrawFundsERC20(target, tokenAddress);
  }
}
