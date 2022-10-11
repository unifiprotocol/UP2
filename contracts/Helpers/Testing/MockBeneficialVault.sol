// // SPDX-License-Identifier: MIT
// /**
//   ∩~~~~∩ 
//   ξ ･×･ ξ 
//   ξ　~　ξ 
//   ξ　　 ξ 
//   ξ　　 “~～~～〇 
//   ξ　　　　　　 ξ 
//   ξ ξ ξ~～~ξ ξ ξ 
// 　 ξ_ξξ_ξ　ξ_ξξ_ξ
// Alpaca Fin Corporation
// */

// pragma solidity ^0.8.7;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts/utils/math/Math.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

// import "./Interfaces/IDebtToken.sol";
// import "./Interfaces/IVault.sol";
// import "./Interfaces/IFairLaunch.sol";
// import "./Utils/SafeToken.sol";
// import "./Utils/WNativeRelayer.sol";

// abstract contract MockBeneficialVault is IVault, ERC20, ReentrancyGuard {
//   address public override token;

//   /// @dev Return the total token entitled to the token holders. Be careful of unaccrued interests.
//   function totalToken() public view override returns (uint256) {
//     return 1;
//   }

//   /// @dev Add more token to the lending pool. Hope to get some good returns.
//   function deposit(uint256 amountToken) external payable override {}

//   /// @dev Withdraw token from the lending and burning ibToken.
//   function withdraw(uint256 share) external override nonReentrant {}
// }
