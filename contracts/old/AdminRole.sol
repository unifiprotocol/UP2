//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;


import "./Roles.sol";
import "./OwnerRole.sol";

contract AdminRole is OwnerRole {
    using Roles for Roles.Role;

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);

    Roles.Role private _admins;

    constructor () {
        _addAdmin(msg.sender);
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return _admins.has(account);
    }

    function addAdmin(address account) public onlyOwner {
        _addAdmin(account);
    }

    function removeAdmin(address account) public onlyOwner {
        _removeAdmin(account);
    }


    function renounceAdmin() public {
        _removeAdmin(msg.sender);
    }

    function _addAdmin(address account) internal {
        _admins.add(account);
        emit AdminAdded(account);
    }

    function _removeAdmin(address account) internal {
        _admins.remove(account);
        emit AdminRemoved(account);
    }
}
