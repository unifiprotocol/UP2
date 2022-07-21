// SPDX-License-Identifier: MIT

import "./Strategy.sol";

pragma solidity ^0.8.4;

contract Vanilla is Strategy {
    constructor(address _safeWithdrawAddress) Strategy(_safeWithdrawAddress) {}
}
