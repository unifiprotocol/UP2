//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Roles.sol";

contract OwnerRole {
  


    event OwnerRemoved(address indexed account);
    event OwnershipTransferred(address indexed previousAccount,address indexed newAccount);

    address private _owner;

    constructor () {
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
        emit OwnershipTransferred(_owner,newOwner);
        _owner = newOwner ;
        
    }

    function renounceOwnership() public onlyOwner {
       
         emit OwnershipTransferred(address(0), _owner);
        _owner = address(0);
    }
}
