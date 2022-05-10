//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "hardhat/console.sol";

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping(address => bool) bearer;
  }

  /**
   * @dev give an account access to this role
   */
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

  /**
   * @dev remove an account's access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

  /**
   * @dev check if an account has this role
   * @return bool
   */
  function has(Role storage role, address account) internal view returns (bool) {
    require(account != address(0));
    return role.bearer[account];
  }
}

contract OwnerRole {
  event OwnerRemoved(address indexed account);
  event OwnershipTransferred(address indexed previousAccount, address indexed newAccount);

  address private _owner;

  constructor() {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  modifier onlyOwner() {
    require(isOwner(msg.sender));
    _;
  }

  function isOwner(address account) public view returns (bool) {
    return _owner == account;
  }

  function transferOwnership(address account) public onlyOwner {
    _transferOwnership(account);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(address(0), _owner);
    _owner = address(0);
  }
}

contract MinterRole is OwnerRole {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private _minters;

  constructor() {
    _addMinter(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return _minters.has(account);
  }

  function addMinter(address account) public onlyMinter {
    _addMinter(account);
  }

  function renounceMinter() public {
    _removeMinter(msg.sender);
  }

  function _addMinter(address account) internal {
    _minters.add(account);
    emit MinterAdded(account);
  }

  function _removeMinter(address account) internal {
    _minters.remove(account);
    emit MinterRemoved(account);
  }
}

interface IBEP20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);

  event ProposalUpdated(address indexed owner, uint256 proposalID, bool result, uint256 value);
}

contract UPv2 is MinterRole {
  string private _name;
  string private _symbol;
  uint8 private _decimals;
  uint256 private _mintRate = 95000;
  uint256 private totalUPBurnt = 0;
  uint256 private totalFeesGiven = 0;
  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowed;
  uint256 private _totalSupply;
  address public controllerAddress;

  uint256 public nativedBorrowed = 0;
  uint256 public upBorrowed = 0;

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event JustDeposit(address indexed owner, uint256 value);
  event UpdateMintRate(uint256 _amount);
  event BorrowNative(uint256 _amount);
  event BorrowUP(uint256 _amount);
  event UpdateControllerAddress(address _newController);
  event ClearNativeDebt(uint256 amount);
  event ClearUPDebt(uint256 amount);

  constructor(uint8 _tokenDecimals, string memory _tokenName) payable {
    _name = _tokenName;
    _symbol = _tokenName;
    _decimals = _tokenDecimals; //set it same as blockchain decimals
    //preset totalSupply here
  }

  modifier onlyController() {
    require(msg.sender == controllerAddress, "Unifi : Only controller");
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param to The address that will receive the minted tokens.
   * @param amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address to, uint256 amount) public payable onlyMinter returns (bool) {
    require(msg.value == amount, "Invalid native token");
    uint256 Value = getVirtualPriceForMinting(amount);
    uint256 MintAmount = (amount * (_mintRate) * (1e18)) / (Value * (100000));
    _mint(to, MintAmount);

    return true;
  }

  /**
   * @dev Deposits a number of native token to return debt
   * @param value The amount of token to be burned.
   */
  function justDeposit(uint256 value) public payable {
    _justDeposit(msg.sender, value);
  }

  /**
   * @return the number UP redeem price legacy use
   */
  function getVirtualPrice() public view returns (uint256) {
    uint256 baseTokenbal = getNativeTotal();
    uint256 Value = (baseTokenbal * (1e18)) / (_totalSupply - upBorrowed);
    return Value;
  }

  /**
   * @return the number UP redeem price
   */
  function getRedeemValue() public view returns (uint256) {
    uint256 baseTokenbal = getNativeTotal();
    uint256 Value = (baseTokenbal * (1e18)) / (_totalSupply - upBorrowed);
    return Value;
  }

  function getVirtualPriceForMinting(uint256 value) public view returns (uint256) {
    uint256 baseTokenbal = getNativeTotal() - value;
    uint256 Value = (baseTokenbal * (1e18)) / (_totalSupply - upBorrowed);
    return Value;
  }

  /**
   * @return the total number of native token backing UP
   */
  function getNativeTotal() public view returns (uint256) {
    return (address(this).balance + nativedBorrowed);
  }

  /**
   * @dev Staking Controller to borrow native
   * @param _borrowNativeAmount The amount of Native tokens to borrow
   */
  function borrowNative(uint256 _borrowNativeAmount) external onlyController {
    require(address(this).balance >= _borrowNativeAmount, "Unifi: not enough supply to borrow");
    nativedBorrowed += _borrowNativeAmount;
    payable(address(controllerAddress)).transfer(_borrowNativeAmount);
    emit BorrowNative(_borrowNativeAmount);
  }

  /**
   * @dev Staking Controller to borrow UP
   * @param _borrowUPAmount The amount of UP tokens to borrow
   */
  function borrowUP(uint256 _borrowUPAmount) external onlyController {
    upBorrowed += _borrowUPAmount;
    _mint(controllerAddress, _borrowUPAmount);
    emit BorrowUP(_borrowUPAmount);
  }

  /**
   * @dev Staking Controller to clear UP debt, staking controller to perform a justDeposit
   * @param amount The amount of UP tokens to Clear
   */
  function clearUPDebt(uint256 amount) external onlyController {
    require(amount <= upBorrowed, "Unifi Invalid UP debt amount");
    upBorrowed = upBorrowed - amount;
    emit ClearUPDebt(amount);
  }

  /**
   * @dev Staking Controller to clear Native debt
   * @param amount The amount of native tokens to Clear
   */
  function clearNativeDebt(uint256 amount) external onlyController {
    require(amount <= nativedBorrowed, "Unifi Invalid Native debt amount");
    nativedBorrowed = nativedBorrowed - amount;
    emit ClearNativeDebt(amount);
  }

  /**
   * @dev Update staking controller address
   * @param _newController new staking controller address
   */
  function updateControllerAddress(address _newController) public onlyOwner {
    controllerAddress = _newController;
    emit UpdateControllerAddress(_newController);
  }

  /**
   * @dev Update UP mintrate
   * @param _amount amount based of 100000
   */
  function updateMintRate(uint256 _amount) public onlyOwner {
    _mintRate = _amount;
    emit UpdateMintRate(_amount);
  }

  /**
   * @dev Total number of tokens in existence exclude minted UP
   */
  function totalSupply() public view returns (uint256) {
    return _totalSupply - upBorrowed;
  }

  /**
   * @dev Function to return total number of native toekns given out by redeem.
   */
  function getTotalFeesGiven() public view returns (uint256) {
    return totalFeesGiven;
  }

  /**
   * @dev Function to return total number of UP tokens burn.
   */
  function getTotalUPBurnt() public view returns (uint256) {
    return totalUPBurnt;
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param value The amount that will be created.
   */
  function _mint(address account, uint256 value) internal {
    require(account != address(0));

    _totalSupply = _totalSupply + (value);
    _balances[account] = _balances[account] + (value);
    emit Transfer(address(0), account, value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account and returns the backed value
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burn(address account, uint256 value) internal {
    require(account != address(0));
    uint256 virtualPrice = getVirtualPrice();
    uint256 redeemValue = (virtualPrice * (value)) / (1e18);
    totalUPBurnt = totalUPBurnt + (value);
    totalFeesGiven = totalFeesGiven + (redeemValue);
    payable(address(account)).transfer(redeemValue);
    _totalSupply = _totalSupply - (value);
    _balances[account] = _balances[account] - (value);
    emit Transfer(account, address(0), value);
  }

  /**
   * @dev Internal function that repays BNB owed to the smart contract
   * account.
   * @param value The amount repayed.
   */
  function _justDeposit(address depositor, uint256 value) internal {
    emit JustDeposit(depositor, value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender's allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burnFrom(address account, uint256 value) internal {
    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    _allowed[account][msg.sender] = _allowed[account][msg.sender] - (value);
    _burn(account, value);
  }

  /**
   * @dev Withdraw airdrop tokens or accidental transfer
   * @param tokenAddress The aToken Address
   * @param amount Amount to withdraw
   */
  function transferOtherTokens(address tokenAddress, uint256 amount)
    public
    onlyOwner
    returns (bool)
  {
    require(address(this) != tokenAddress);
    IBEP20 otherTokens = IBEP20(tokenAddress);
    otherTokens.transfer(msg.sender, amount);
    return true;
  }

  fallback() external payable {
    if (msg.value > 0) {
      _justDeposit(msg.sender, msg.value);
    }
  }

  receive() external payable {
    if (msg.value > 0) {
      _justDeposit(msg.sender, msg.value);
    }
  }
}
