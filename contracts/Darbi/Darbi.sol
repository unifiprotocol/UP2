// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/lib/contracts/libraries/Babylonian.sol";
import "../Libraries/UniswapHelper.sol";
import "../Helpers/Safe.sol";
import "../UPController.sol";
import "./UPMintDarbi.sol";

contract Darbi is AccessControl, Safe {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  address public factory;
  IUniswapV2Router02 public router;
  IWETH public WETH;
  UPController public UP_CONTROLLER;
  UPMintDarbi public DARBI_MINTER;

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ONLY_ADMIN");
    _;
  }

  constructor(
    address _factory,
    address _router,
    address _WETH,
    address _UP_CONTROLLER,
    address _darbiMinter
  ) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    factory = _factory;
    router = IUniswapV2Router02(_router);
    WETH = IWETH(_WETH);
    UP_CONTROLLER = UPController(payable(_UP_CONTROLLER));
    DARBI_MINTER = UPMintDarbi(payable(_darbiMinter));
  }

  receive() external payable {
    WETH.deposit{value: msg.value}();
  }

  function arbitrage() public onlyAdmin {
    uint256 balance1 = IERC20(address(WETH)).balanceOf(address(this));
    uint256 price1 = UP_CONTROLLER.getVirtualPrice();
    uint256 balance0 = price1 * balance1;
    uint256 price0 = UniswapV2Library.quote(1, balance0, balance1);
    address UP_TOKEN = UP_CONTROLLER.UP_TOKEN();

    address[2] memory swappedTokens = [UP_TOKEN, address(WETH)];
    uint256[2] memory truePriceTokens = [price0, price1];
    uint256[2] memory maxSpendTokens = [balance0, balance1];

    require(truePriceTokens[0] != 0 && truePriceTokens[1] != 0, "SwapToPrice: ZERO_PRICE");
    // caller can specify 0 for either if they wish to swap in only one direction, but not both
    require(maxSpendTokens[0] != 0 || maxSpendTokens[1] != 0, "SwapToPrice: ZERO_SPEND");

    bool aToB;
    uint256 amountIn;

    (uint256 reserveA, uint256 reserveB) = UniswapHelper.getReserves(
      factory,
      swappedTokens[0],
      swappedTokens[1]
    );
    (aToB, amountIn) = UniswapHelper.computeTradeToMoveMarket(
      truePriceTokens[0],
      truePriceTokens[1],
      reserveA,
      reserveB
    );

    require(amountIn > 0, "SwapToPrice: ZERO_AMOUNT_IN");

    // spend up to the allowance of the token in
    uint256 maxSpend = aToB ? maxSpendTokens[0] : maxSpendTokens[1];

    // IF ATOB === TRUE WE HAVE TO GET MINT $UP !!!
    if (aToB) {
      mintUP(maxSpend);
    }

    if (amountIn > maxSpend) {
      amountIn = maxSpend;
    }

    address tokenIn = aToB ? swappedTokens[0] : swappedTokens[1];
    address tokenOut = aToB ? swappedTokens[1] : swappedTokens[0];

    TransferHelper.safeApprove(tokenIn, address(router), amountIn);

    address[] memory path = new address[](2);
    path[0] = tokenIn;
    path[1] = tokenOut;

    router.swapExactTokensForTokens(
      amountIn,
      0, // amountOutMin: we can skip computing this number because the math is tested within the uniswap tests.
      path,
      address(this),
      1 minutes
    );

    // IF ATOB === TRUE WE ARE GETTING $UP, SO WE HAVE TO REDEEM IT
    if (aToB) {
      redeemUP();
    }
  }

  function moveMarketBuyAmount() public returns (bool aToB, uint256 amountIn) {
    address[2] memory swappedTokens = [UP_TOKEN, address(WETH)];
    (uint256 reserveA, uint256 reserveB) = UniswapHelper.getReserves(
      factory,
      swappedTokens[0],
      swappedTokens[1]
    );
    (uint256 price0, uint256 price1) = getVirtualPrice();
    (aToB, amountIn) = UniswapHelper.computeTradeToMoveMarket(price0, price1, reserveA, reserveB);
    return (aToB, amountIn);
  }

  function getVirtualPrice() public returns (uint256, uint256) {
    uint256 price1 = UP_CONTROLLER.getVirtualPrice();
    uint256 balance0 = price1 * balance1;
    uint256 price0 = UniswapV2Library.quote(1, balance0, balance1);
    address UP_TOKEN = UP_CONTROLLER.UP_TOKEN();
    return (price0, price1);
  }

  function mintUP(uint256 amount) internal {
    WETH.withdraw(amount);
    DARBI_MINTER.mintUP{value: amount}();
  }

  function redeemUP() internal {
    UP_CONTROLLER.redeem(IERC20(UP_CONTROLLER.UP_TOKEN()).balanceOf(address(this)));
    WETH.deposit{value: address(this).balance}();
  }

  function setFactory(address _factory) public onlyAdmin {
    require(_factory != address(0));
    factory = _factory;
  }

  function setRouter(address _router) public onlyAdmin {
    require(_router != address(0));
    router = IUniswapV2Router02(_router);
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
}
