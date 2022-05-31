// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IAAVEHarmonyTest { 
    function checkRewardsBalance() external view returns (uint256);
    function checkAAVEBalance() external view  returns (uint256);
    function checkUnclaimedEarnings() external view returns (uint256);
    function depositAAVE() external payable;
}