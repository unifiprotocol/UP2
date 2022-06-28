// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IFactory {
    function INIT_CODE_PAIR_HASH() external pure returns(bytes32);
}