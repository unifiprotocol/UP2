// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract UP is ERC20, AccessControl {
  bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");

  modifier onlyController() {
    require(hasRole(CONTROLLER_ROLE, msg.sender), "ONLY_CONTROLLER");
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

  function justBurn(uint256 amount) external {
    burn(amount);
  }

  function mint(address account, uint256 amount) public onlyController {
    _mint(account, amount);
  }
}
