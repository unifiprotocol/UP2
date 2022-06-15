// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "../IStrategy.sol";

interface IAAVEHarmonyTest is IStrategy { 
    function checkRewardsBalance() external view returns (uint256);
    function checkAAVEBalance() external view returns (uint256);
    function checkUnclaimedEarnings() external view returns (uint256);
    function deposit(uint256 amount) external payable override returns (bool);
    function withdrawAAVE() external returns (uint256);
    function claimAAVERewards() external returns (uint256);
    function checkRewards() external view override returns (IStrategy.Rewards memory);
    function gather() override external;
    function withdrawFunds(address) external returns (bool);
}