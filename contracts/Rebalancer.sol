// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./UPController.sol";
import "./Strategies/IStrategy.sol";
import "./Helpers/Safe.sol";

contract Rebalancer is AccessControl, Pausable, Safe {
  bytes32 public constant STAKING_ROLE = keccak256("STAKING_ROLE");
  IUniswapV2Router01 public router;
  address public WETH = address(0);
  address public UPaddress = address(0);
  address public strategy = address(0);
  address public unifiRouter = address(0);
  address public liquidityPool = address(0);
  address payable public UP_CONTROLLER = payable(address(0));
  uint256[3] public distribution = [90, 5, 5];

  modifier onlyStaking() {
    require(hasRole(STAKING_ROLE, msg.sender), "ONLY_STAKING");
    _;
  }

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ONLY_ADMIN");
    _;
  }

  constructor(
    address _WETH,
    address _UPAddress,
    address _UPController,
    address _Strategy,
    address _unifiRouter,
    address _liquidityPool
  ) {
    WETH = _WETH;
    UPaddress = _UPAddress;
    UP_CONTROLLER = payable(_UPController);
    strategy = _Strategy;
    unifiRouter = _unifiRouter;
    liquidityPool = _liquidityPool;
  }

  receive() external payable {}

  function rebalance() public onlyAdmin {
    IStrategy(strategy).gather();

    uint256 distribution1 = ((address(this).balance * (distribution[0] * 100)) / 10000);
    // uint256 distribution2 = ((address(this).balance * (distribution[1] * 100)) / 10000);
    uint256 distribution3 = ((address(this).balance * (distribution[2] * 100)) / 10000);
    _distribution1(distribution1);
    // _distribution2(distribution2);
    _distribution3(distribution3);
  }

  function _distribution1(uint256 _amount) internal {
    /// distribution 1 goes to the strategy
    IStrategy(strategy).deposit(_amount);
  }

  // function _distribution2(uint256 _amount) internal {
  //   /// distribution 2 goes to the Unifi LP
  //   // IUniswapV2Router02 router = IUniswapV2Router02(unifiRouter);
  //   // Solutions for LP Price - 
  //   // Using Library + Factory (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
  //   // Using Pair - function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

  //   // uint256 lpPrice = router.getAmountsOut(1, [WETH, UPaddress]); // should be re-done to not based on getAmountOut but based on LP price using IUniswapPair / Babylonian.
  //   uint256 borrowAmount = lpPrice * _amount;
  //   UPController(UP_CONTROLLER).borrowUP(borrowAmount, address(this));
  //   uint256 distribution2Slippage = ((_amount * (1 * 100)) / 10000); // 1%
  //   uint256 amountTokenMin = ((borrowAmount * (1 * 100)) / 10000); // 1%
  //   router.addLiquidityETH(
  //     UPaddress,
  //     _amount,
  //     amountTokenMin,
  //     distribution2Slippage,
  //     address(this),
  //     block.timestamp + 20 minutes
  //   );
  // }

  function _distribution3(uint256 _amount) internal {
    /// distribution 3 goes to the UPController
    (bool successTransfer, ) = address(UP_CONTROLLER).call{value: _amount}("");
    require(successTransfer, "DISTRIBUTION3_FAILED");
  }

  // GETTER & SETTERS
  function setDistribution(uint256[3] memory _distribution) public onlyAdmin {
    require(_distribution[0] > 0, "INVALID_PARAM_0");
    require(_distribution[1] > 0, "INVALID_PARAM_1");
    require(_distribution[2] > 0, "INVALID_PARAM_2");
    require((_distribution[0] + _distribution[1] + _distribution[2]) == 100, "INVALID_PARAMS");
    distribution = _distribution;
  }

  function setUPController(address newAddress) public onlyAdmin {
    UP_CONTROLLER = payable(newAddress);
  }

  function setStrategy(address newAddress) public onlyAdmin {
    strategy = newAddress;
  }

  function setUnifiRouter(address newAddress) public onlyAdmin {
    unifiRouter = newAddress;
  }

  function withdrawFunds(address target) public onlyAdmin returns (bool) {
    return _withdrawFunds(target);
  }

  function withdrawFundsERC20(address target, address tokenAddress)
    public
    onlyAdmin
    returns (bool)
  {
    return _withdrawFundsERC20(target, tokenAddress);
  }

  /// @notice Permissioned function to pause UPaddress Controller
  function pause() public onlyAdmin {
    _pause();
  }

  /// @notice Permissioned function to unpause UPaddress Controller
  function unpause() public onlyAdmin {
    _unpause();
  }
}
