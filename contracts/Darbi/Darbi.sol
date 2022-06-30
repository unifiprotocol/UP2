// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/lib/contracts/libraries/Babylonian.sol";
import "../Libraries/UniswapHelper.sol";
import "../Helpers/Safe.sol";
import "../UPController.sol";
import "./UPMintDarbi.sol";

contract Darbi is Safe {
  using SafeERC20 for IERC20;

  address public factory;
  address public WETH;
  uint256 public arbitrageThreshold = 100000;
  mapping(address => bool) public admins;
  IERC20 public UP_TOKEN;
  IUniswapV2Router02 public router;
  UPController public UP_CONTROLLER;
  UPMintDarbi public DARBI_MINTER;

  modifier onlyAdmin() {
    require(admins[msg.sender], "ONLY_ADMINS");
    _;
  }

  constructor(
    address _factory,
    address _router,
    address _WETH,
    address _UP_CONTROLLER,
    address _darbiMinter
  ) {
    factory = _factory;
    WETH = _WETH;
    router = IUniswapV2Router02(_router);
    UP_CONTROLLER = UPController(payable(_UP_CONTROLLER));
    DARBI_MINTER = UPMintDarbi(payable(_darbiMinter));
    UP_TOKEN = IERC20(payable(UP_CONTROLLER.UP_TOKEN()));
    admins[msg.sender] = true;
  }

  receive() external payable {}

  function arbitrage() public onlyAdmin {
    (
      bool aToB,
      uint256 amountIn,
      uint256 reserves0,
      uint256 reserves1,
      uint256 backedValue
    ) = moveMarketBuyAmount();
    // Will Return 0 if MV = BV exactly, we are using <100 to add some slippage
    // TODO: Should the ArbitrageThreshold be reflective of the gas cost? In other words, the profit must be greater than the gas refund.
    if (amountIn < arbitrageThreshold) return;
    // aToB == true == Buys UP
    // aToB == fals == Sells UP
    uint256 balances = address(this).balance;
    // If Buying UP
    if (aToB) {
      _arbitrageBuy(balances, amountIn, backedValue, reserves0, reserves1);
    } else {
      _arbitrageSell(balances, amountIn, backedValue);
    }
  }

  function _arbitrageBuy(
    uint256 balances,
    uint256 amountIn,
    uint256 backedValue,
    uint256 reserves0,
    uint256 reserves1
  ) internal {
    uint256 actualAmountIn = amountIn <= balances ? amountIn : balances; //Value is going to native
    uint256 expectedReturn = UniswapHelper.getAmountOut(actualAmountIn, reserves0, reserves1); // Amount of UP expected from Buy
    uint256 expectedNativeReturn = (expectedReturn * backedValue) / 1e18; //Amount of Native Tokens Expected to Receive from Redeem
    uint256 upControllerBalance = address(UP_CONTROLLER).balance;
    if (upControllerBalance < expectedNativeReturn) {
      uint256 upOutput = (upControllerBalance * 1e18) / backedValue; //Value in UP Token
      actualAmountIn = UniswapHelper.getAmountOut(upOutput, reserves1, reserves0); // Amount of UP expected from Buy
    }

    address[] memory path = new address[](2);
    path[0] = WETH;
    path[1] = address(UP_TOKEN);

    uint256[] memory amounts = router.swapExactETHForTokens(
      actualAmountIn,
      path,
      address(this),
      block.timestamp + 150
    );

    UP_TOKEN.approve(address(UP_CONTROLLER), amounts[1]);
    UP_CONTROLLER.redeem(amounts[1]);
    /// TODO: Gas Refund HERE
    uint256 diffBalances = address(this).balance - balances;
    (bool success, ) = address(UP_CONTROLLER).call{value: diffBalances}("");
    require(success, "FAIL_SENDING_BALANCES_TO_CONTROLLER");
  }

  function _arbitrageSell(
    uint256 balances,
    uint256 amountIn,
    uint256 backedValue
  ) internal {
    // If selling UP
    uint256 darbiBalanceMaximumUpToMint = (balances * 1e18) / backedValue; // Amount of UP that we can mint with current balances
    uint256 actualAmountIn = amountIn <= darbiBalanceMaximumUpToMint
      ? amountIn
      : darbiBalanceMaximumUpToMint; // Value in UP
    uint256 nativeToMint = (actualAmountIn * backedValue) / 1e18;
    DARBI_MINTER.mintUP{value: nativeToMint}();

    address[] memory path = new address[](2);
    path[0] = address(UP_TOKEN);
    path[1] = WETH;

    uint256 up2Balance = UP_TOKEN.balanceOf(address(this));
    UP_TOKEN.approve(address(router), up2Balance);

    router.swapExactTokensForETH(up2Balance, 0, path, address(this), block.timestamp + 150);
    uint256 diffBalances = balances - address(this).balance;
    (bool success, ) = address(UP_CONTROLLER).call{value: diffBalances}("");
    require(success, "FAIL_SENDING_BALANCES_TO_CONTROLLER");
    // This Sells UP
  }

  function moveMarketBuyAmount()
    public
    view
    onlyAdmin
    returns (
      bool aToB,
      uint256 amountIn,
      uint256 reserves0,
      uint256 reserves1,
      uint256 upPrice
    )
  {
    address[2] memory swappedTokens = [address(UP_TOKEN), address(WETH)];
    (reserves0, reserves1) = UniswapHelper.getReserves(factory, swappedTokens[0], swappedTokens[1]);
    upPrice = UP_CONTROLLER.getVirtualPrice();
    (aToB, amountIn) = UniswapHelper.computeTradeToMoveMarket(
      1000000000000000000, // Ratio = 1:UPVirtualPrice
      upPrice,
      reserves0,
      reserves1
    );
    return (aToB, amountIn, reserves0, reserves1, upPrice);
  }

  function redeemUP() internal {
    UP_CONTROLLER.redeem(IERC20(UP_CONTROLLER.UP_TOKEN()).balanceOf(address(this)));
  }

  function setFactory(address _factory) public onlyAdmin {
    require(_factory != address(0));
    factory = _factory;
  }

  function setArbitrageThreshold(uint256 _threshold) public onlyAdmin {
    require(_threshold > 0);
    arbitrageThreshold = _threshold;
  }

  function setRouter(address _router) public onlyAdmin {
    require(_router != address(0));
    router = IUniswapV2Router02(_router);
  }

  function setDarbiMinter(address _newMinter) public onlyAdmin {
    require(_newMinter != address(0));
    DARBI_MINTER = UPMintDarbi(payable(_newMinter));
  }

  function addAdmin(address _newAdmin) public onlyAdmin {
    admins[_newAdmin] = true;
  }

  function removeAdmin(address _admin) public onlyAdmin {
    admins[_admin] = false;
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
