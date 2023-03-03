// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUnifiPair is IERC20 {
  function claimUP(address to) external returns (uint256 upReceived);

  function getReserves() external view returns (uint112 reserveA, uint112 reserveB);
}
