// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRebalancer {
    function allocationLP() external view returns (uint256);
    function allocationRedeem() external view returns (uint256);
}