// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract UP is ERC20, AccessControl {
  bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");
  bytes32 public constant LEGACY_MINT_ROLE = keccak256("LEGACY_MINT_ROLE");
  address public UP_CONTROLLER = address(0);

  modifier onlyMint() {
    require(hasRole(MINT_ROLE, msg.sender), "ONLY_MINT");
    _;
  }

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ONLY_ADMIN");
    _;
  }

  constructor() ERC20("UP", "UP") {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function burn(uint256 amount) public {
    _burn(_msgSender(), amount);
  }

  function burnFrom(address account, uint256 amount) public {
    _spendAllowance(account, _msgSender(), amount);
    _burn(account, amount);
  }

  /// @notice Retrocompatible function with v1
  function justBurn(uint256 amount) external {
    burn(amount);
  }

  /// @notice Mints token and have logic for supporting legacy mint logic
  function mint(address to, uint256 amount) public payable onlyMint {
    _mint(to, amount);
    if (hasRole(LEGACY_MINT_ROLE, msg.sender) && UP_CONTROLLER != address(0)) {
      (bool success, ) = UP_CONTROLLER.call{value: address(this).balance}("");
      require(success, "LEGACY_MINT_FAILED");
    }
  }

  /// @notice Sets a controller address that will receive the funds from LEGACY_MINT_ROLE
  function setController(address newController) public onlyAdmin {
    UP_CONTROLLER = newController;
  }
}
