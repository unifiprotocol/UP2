// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./UP.sol";
import "./Helpers/Safe.sol";

/// @title UP Controller
/// @author dxffffff & A Fistful of Stray Cat Hair
/// @notice This controller back up the UP token and has the logic for borrowing tokens.

contract UPController is AccessControl, Safe, Pausable {
  bytes32 public constant REBALANCER_ROLE = keccak256("REBALANCER_ROLE");
  bytes32 public constant REDEEMER_ROLE = keccak256("REDEEMER_ROLE");

  address payable public UP_TOKEN = payable(address(0));
  uint256 public nativeBorrowed = 0;
  uint256 public upBorrowed = 0;

  event SyntheticMint(address _from, uint256 _amount, uint256 _newUpBorrowed);
  event BorrowNative(address _from, uint256 _amount, uint256 _newNativeBorrowed);
  event Repay(uint256 _nativeAmount, uint256 _upAmount);
  event Redeem(uint256 _upAmount, uint256 _redeemAmount);

  modifier onlyRebalancer() {
    require(hasRole(REBALANCER_ROLE, msg.sender), "ONLY_REBALANCER");
    _;
  }

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ONLY_ADMIN");
    _;
  }

  modifier onlyRedeemer() {
    require(hasRole(REDEEMER_ROLE, msg.sender), "ONLY_REDEEMER");
    _;
  }

  constructor(address _UP) {
    require(_UP != address(0), "Invalid UP address");
    UP_TOKEN = payable(_UP);
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  receive() external payable {}

  /// @notice Returns price of UP token based on its reserves
  function getVirtualPrice() public view returns (uint256) {
    if (getNativeBalance() == 0) return 0;
    return ((getNativeBalance() * 1e18) / actualTotalSupply());
  }

  /// @notice Returns price of UP token based on its reserves minus amount sent to the contract
  function getVirtualPrice(uint256 sentValue) public view returns (uint256) {
    if (getNativeBalance() == 0) return 0;
    uint256 nativeBalance = getNativeBalance() - sentValue;
    return ((nativeBalance * 1e18) / actualTotalSupply());
  }

  /// @notice Computed the actual native balances of the contract
  function getNativeBalance() public view returns (uint256) {
    return address(this).balance + nativeBorrowed;
  }

  /// @notice Computed total supply of UP token
  function actualTotalSupply() public view returns (uint256) {
    return UP(UP_TOKEN).totalSupply() - upBorrowed;
  }

  /// @notice Borrows native token from the back up reserves
  function borrowNative(uint256 _borrowAmount, address _to) public onlyRebalancer whenNotPaused {
    require(address(this).balance >= _borrowAmount, "NOT_ENOUGH_BALANCE");
    (bool success, ) = _to.call{value: _borrowAmount}("");
    nativeBorrowed += _borrowAmount;
    require(success, "BORROW_NATIVE_FAILED");
    emit BorrowNative(_to, _borrowAmount, nativeBorrowed);
  }

  /// @notice Borrows UP token minting it
  function borrowUP(uint256 _borrowAmount, address _to) public onlyRebalancer whenNotPaused {
    upBorrowed += _borrowAmount;
    UP(UP_TOKEN).mint(_to, _borrowAmount);
    emit SyntheticMint(msg.sender, _borrowAmount, upBorrowed);
  }

  function mintSyntheticUP(uint256 _mintAmount, address _to) public onlyRebalancer {
    borrowUP(_mintAmount, _to);
  }

  /// @notice Mints UP based on virtual price - UPv1 logic
  function mintUP(address to) external payable whenNotPaused {
    require(msg.sender == UP_TOKEN, "NON_UP_CONTRACT");
    uint256 mintAmount = (msg.value * getVirtualPrice(msg.value)) / 1e18;
    UP(UP_TOKEN).mint(to, mintAmount);
  }

  /// @notice Allows to return back borrowed amounts to the controller
  function repay(uint256 upAmount) public payable onlyRebalancer whenNotPaused {
    require(upAmount <= upBorrowed, "UP_AMOUNT_GT_BORROWED");
    require(msg.value <= nativeBorrowed, "NATIVE_AMOUNT_GT_BORROWED");
    UP(UP_TOKEN).transferFrom(msg.sender, address(this), upAmount);
    upBorrowed -= upAmount;
    nativeBorrowed -= msg.value;
    emit Repay(msg.value, upAmount);
  }

  /// @notice Swaps UP token by native token
  function redeem(uint256 upAmount) public onlyRedeemer whenNotPaused {
    require(upAmount > 0, "AMOUNT_EQ_0");
    uint256 redeemAmount = (getVirtualPrice() * upAmount) / 1e18;
    UP(UP_TOKEN).burnFrom(msg.sender, upAmount);
    (bool success, ) = msg.sender.call{value: redeemAmount}("");
    require(success, "REDEEM_FAILED");
    emit Redeem(upAmount, redeemAmount);
  }

  function pause() public onlyAdmin {
    _pause();
  }

  function unpause() public onlyAdmin {
    _unpause();
  }

  function withdrawFunds(address target) public onlyAdmin returns (bool) {
    return _withdrawFunds(target);
  }

  function withdrawFundsERC20(address target, address tokenAddress)
    public
    onlyAdmin
    returns (bool)
  {
    return _withdrawFundsERC20(target, tokenAddress);
  }
}
