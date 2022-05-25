// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/lib/contracts/libraries/Babylonian.sol";
import "../Libraries/FullMath.sol";
import "../Libraries/UniswapHelper.sol";
import "../Helpers/Safe.sol";
import "../UPController.sol";

contract Darbi is AccessControl, Safe {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  IUniswapV2Router02 public router;
  address public factory;
  IWETH public WETH;
  address payable public UP_CONTROLLER;

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ONLY_ADMIN");
    _;
  }

  constructor(
    address _factory,
    address _router,
    address _WETH,
    address _UP_CONTROLLER
  ) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    factory = _factory;
    router = IUniswapV2Router02(_router);
    WETH = IWETH(_WETH);
    UP_CONTROLLER = payable(_UP_CONTROLLER);
  }

  receive() external payable {
    WETH.deposit{value: msg.value}();
  }

  function arbitrage() public onlyAdmin {
    UPController controller = UPController(UP_CONTROLLER);
    address UP_TOKEN = controller.UP_TOKEN();
    uint256 balance0 = IERC20(UP_TOKEN).balanceOf(address(this));
    uint256 balance1 = IERC20(address(WETH)).balanceOf(address(this));
    uint256 price1 = controller.getVirtualPrice();
    uint256 price0 = uint256(1).div(price1);

    swapToPrice(
      [UP_TOKEN, address(WETH)],
      [price0, price1],
      [balance0, balance1],
      address(this),
      20 minutes
    );
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

  /**
   * @notice Swaps an amount of either token such that the trade results in the uniswap pair's price being as close as
   * possible to the truePrice.
   * @dev True price is expressed in the ratio of token A to token B.
   * @dev The caller must approve this contract to spend whichever token is intended to be swapped.
   * @param swappedTokens array of addresses which are to be swapped. The order does not matter as the function will figure
   * out which tokens need to be exchanged to move the market to the desired "true" price.
   * @param truePriceTokens array of unit used to represent the true price. 0th value is the numerator of the true price
   * and the 1st value is the the denominator of the true price.
   * @param maxSpendTokens array of unit to represent the max to spend in the two tokens.
   * @param to recipient of the trade proceeds.
   * @param deadline to limit when the trade can execute. If the tx is mined after this timestamp then revert.
   */
  function swapToPrice(
    address[2] memory swappedTokens,
    uint256[2] memory truePriceTokens,
    uint256[2] memory maxSpendTokens,
    address to,
    uint256 deadline
  ) internal {
    // true price is expressed as a ratio, so both values must be non-zero
    require(truePriceTokens[0] != 0 && truePriceTokens[1] != 0, "SwapToPrice: ZERO_PRICE");
    // caller can specify 0 for either if they wish to swap in only one direction, but not both
    require(maxSpendTokens[0] != 0 || maxSpendTokens[1] != 0, "SwapToPrice: ZERO_SPEND");

    bool aToB;
    uint256 amountIn;
    {
      (uint256 reserveA, uint256 reserveB) = UniswapHelper.getReserves(
        factory,
        swappedTokens[0],
        swappedTokens[1]
      );
      (aToB, amountIn) = computeTradeToMoveMarket(
        truePriceTokens[0],
        truePriceTokens[1],
        reserveA,
        reserveB
      );
    }

    require(amountIn > 0, "SwapToPrice: ZERO_AMOUNT_IN");

    // spend up to the allowance of the token in
    uint256 maxSpend = aToB ? maxSpendTokens[0] : maxSpendTokens[1];

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
      to,
      deadline
    );
  }

  /**
   * @notice Given the "true" price a token (represented by truePriceTokenA/truePriceTokenB) and the reservers in the
   * uniswap pair, calculate: a) the direction of trade (aToB) and b) the amount needed to trade (amountIn) to move
   * the pool price to be equal to the true price.
   * @dev Note that this method uses the Babylonian square root method which has a small margin of error which will
   * result in a small over or under estimation on the size of the trade needed.
   * @param truePriceTokenA the nominator of the true price.
   * @param truePriceTokenB the denominator of the true price.
   * @param reserveA number of token A in the pair reserves
   * @param reserveB number of token B in the pair reserves
   */
  //
  function computeTradeToMoveMarket(
    uint256 truePriceTokenA,
    uint256 truePriceTokenB,
    uint256 reserveA,
    uint256 reserveB
  ) public pure returns (bool aToB, uint256 amountIn) {
    aToB = FullMath.mulDiv(reserveA, truePriceTokenB, reserveB) < truePriceTokenA;

    uint256 invariant = reserveA.mul(reserveB);

    // The trade ∆a of token a required to move the market to some desired price P' from the current price P can be
    // found with ∆a=(kP')^1/2-Ra.
    uint256 leftSide = Babylonian.sqrt(
      FullMath.mulDiv(
        invariant,
        aToB ? truePriceTokenA : truePriceTokenB,
        aToB ? truePriceTokenB : truePriceTokenA
      )
    );
    uint256 rightSide = (aToB ? reserveA : reserveB);

    if (leftSide < rightSide) return (false, 0);

    // compute the amount that must be sent to move the price back to the true price.
    amountIn = leftSide.sub(rightSide);
  }
}
