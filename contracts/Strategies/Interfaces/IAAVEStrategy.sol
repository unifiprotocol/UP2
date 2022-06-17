// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "../IStrategy.sol";

interface IAAVEHarmonyTest is IStrategy { 
    function checkRewardsBalance() external view returns (uint256);
    function checkAAVEBalance() external view returns (uint256);
    function checkAAVEInterest() external view returns (uint256);
    function checkUnclaimedEarnings() external view returns (uint256);
    function checkRewards() external view override returns (IStrategy.Rewards memory);
    function withdraw(uint256 amount) external returns (bool);
    function withdrawAll() external returns (bool);
    function deposit(uint256 amount) external payable override returns (bool);
    function gather() override external;
    function withdrawFunds(address) external returns (bool);
    function pause() external;
    function unpause() external;
    function updateaavePool(address) external;
}