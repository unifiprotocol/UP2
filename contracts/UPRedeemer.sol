// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Helpers/Safe.sol";
import "./UP.sol";
import "./UPController.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title UPWhitelistedMint
/// @author clostao
/// @notice This contract allows to redeem UP in exchange to the corresponding backed value
contract UPRedeemer is AccessControl, Safe, Pausable {
  UP public UP_TOKEN;
  UPController public UP_CONTROLLER;
  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

  event UpdateUPController(address upController);
  event Redeem(address from, uint256 upAmount, uint256 redeemAmount);

  constructor(
    address _UP_TOKEN,
    address _UP_CONTROLLER,
    address _safeTargetAddress
  ) Safe(_safeTargetAddress) {
    require(_UP_TOKEN != address(0), "UPRedeemer: INVALID_UP_ADDRESS");
    require(_UP_CONTROLLER != address(0), "UPRedeemer: INVALID_UP_CONTROLLER_ADDRESS");
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    UP_TOKEN = UP(payable(_UP_TOKEN));
    UP_CONTROLLER = UPController(payable(_UP_CONTROLLER));
  }

  /// @notice Allows any user to redeem the native tokens backing UP
  function redeem(uint256 upAmount) public whenNotPaused {
    UP_TOKEN.transferFrom(msg.sender, address(this), upAmount);
    UP_TOKEN.approve(address(UP_CONTROLLER), upAmount);

    uint256 prevBalance = address(this).balance;
    UP_CONTROLLER.redeem(upAmount);
    uint256 postBalance = address(this).balance;

    require(postBalance > prevBalance, "UPRedeemer: NOT_ENOUGH_UP_REDEEMED");
    uint256 redeemAmount = postBalance - prevBalance;
    (bool success, ) = msg.sender.call{value: redeemAmount}("");
    require(success, "UPRedeemer: FAIL_SENDING_NATIVE");
    emit Redeem(msg.sender, upAmount, redeemAmount);
  }

  function updateUPController(address _UP_CONTROLLER) public onlyRole(OWNER_ROLE) {
    UP_CONTROLLER = UPController(payable(_UP_CONTROLLER));
    emit UpdateUPController(_UP_CONTROLLER);
  }

  function pause() public onlyRole(OWNER_ROLE) {
    _pause();
  }

  function unpause() public onlyRole(OWNER_ROLE) {
    _unpause();
  }

  function withdrawFunds() public onlyRole(OWNER_ROLE) returns (bool) {
    return _withdrawFunds();
  }

  function withdrawFundsERC20(address tokenAddress) public onlyRole(OWNER_ROLE) returns (bool) {
    return _withdrawFundsERC20(tokenAddress);
  }

  receive() external payable {}
}
