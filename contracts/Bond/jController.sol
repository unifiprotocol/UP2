// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract jController is Ownable {
  using SafeERC20 for IERC20;

  address public WETH = address(0);
  address public UP = address(0);
  address public liquidityPool = address(0);
  uint256[3] public distribution = [90, 5, 5];

  constructor(
    address _WETH,
    address _UP,
    address _liquidityPool
  ) {
    WETH = _WETH;
    UP = _UP;
    liquidityPool = _liquidityPool;
  }

  // GETTER & SETTERS
  function setDistribution(uint256[3] memory _distribution) public onlyOwner {
    require(_distribution[0] > 0, "INVALID_PARAM_0");
    require(_distribution[1] > 0, "INVALID_PARAM_1");
    require(_distribution[2] > 0, "INVALID_PARAM_2");
    require((_distribution[0] + _distribution[1] + _distribution[2]) == 100, "INVALID_PARAMS");
    distribution = _distribution;
  }

  function setUPToken(address newAddress) public onlyOwner {
    UP = newAddress;
  }

  function setLiquidityPool(address newAddress) public onlyOwner {
    liquidityPool = newAddress;
  }

  // SAFETY
  function withdrawFunds(address target) public onlyOwner returns (bool) {
    (bool sent, ) = address(target).call{value: address(this).balance}("");
    require(sent, "Failed to send Ether");
    return sent;
  }

  function withdrawFundsERC20(address target, address tokenAddress)
    public
    onlyOwner
    returns (bool)
  {
    IERC20 token = IERC20(tokenAddress);
    token.safeTransferFrom(address(this), target, token.balanceOf(address(this)));
    return true;
  }
}
