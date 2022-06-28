// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@uniswap/lib/contracts/libraries/Babylonian.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../Libraries/UniswapHelper.sol";
import "../Helpers/Safe.sol";
import "../UPController.sol";
import "./UPMintDarbi.sol";

contract Darbi is AccessControl, Safe, Pausable {
  using SafeERC20 for IERC20;
  bytes32 public constant MONITOR_ROLE = keccak256("MONITOR_ROLE");
  address public factory;
  address public WETH;
  uint256 public arbitrageThreshold = 100000;
  IUniswapV2Router02 public router;
  UPController public UP_CONTROLLER;
  UPMintDarbi public DARBI_MINTER;

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ONLY_ADMIN");
    _;
  }

  modifier onlyMonitor() {
    require(hasRole(MONITOR_ROLE, msg.sender), "ONLY_MONITOR_ROLE");
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
    _setupRole(MONITOR_ROLE, msg.sender);
    factory = _factory;
    WETH = _WETH;
    router = IUniswapV2Router02(_router);
    UP_CONTROLLER = UPController(payable(_UP_CONTROLLER));
    DARBI_MINTER = UPMintDarbi(payable(_darbiMinter));
  }

  receive() external payable {}

  function arbitrage() public whenNotPaused onlyMonitor {
    address UP_TOKEN = UP_CONTROLLER.UP_TOKEN();
    (uint256 reserves0, uint256 reserves1) = UniswapHelper.getReserves(factory, UP_TOKEN, WETH);
    // uint256 marketValue = reserves0 / reserves1;
    uint256 backedValue = UP_CONTROLLER.getVirtualPrice();
    address[] memory path;

    (bool aToB, uint256 amountIn) = moveMarketBuyAmount();
    // Will Return 0 if MV = BV exactly, we are using <100 to add some slippage
    if (amountIn < arbitrageThreshold) return;

    // aToB == true == Buys UP
    // aToB == fals == Sells UP
    uint256 balances = address(this).balance;
    uint256 actualAmountIn;
    // If Buying UP
    if (aToB) {
      actualAmountIn = amountIn <= balances ? amountIn : balances; //Value is going to native
      uint256 expectedReturn = UniswapHelper.getAmountOut(actualAmountIn, reserves0, reserves1); // Amount of UP expected from Buy
      uint256 expectedNativeReturn = expectedReturn * backedValue; //Amount of Native Tokens Expected to Receive from Redeem
      uint256 upControllerBalance = address(UP_CONTROLLER).balance;
      if (upControllerBalance < expectedNativeReturn) {
        uint256 upOutput = upControllerBalance / backedValue; //Value in UP Token
        actualAmountIn = UniswapHelper.getAmountOut(upOutput, reserves1, reserves0); // Amount of UP expected from Buy
      }
      path[0] = WETH;
      path[1] = UP_TOKEN;
      uint256[] memory amounts = router.swapExactETHForTokens(
        actualAmountIn,
        path,
        address(this),
        block.timestamp + 20 minutes
      );
      UP_CONTROLLER.redeem(amounts[1]);
      /// TODO: Gas Refund HERE
      uint256 diffBalances = address(this).balance - balances;
      (bool success, ) = address(UP_CONTROLLER).call{value: diffBalances}("");
      require(success, "FAIL_SENDING_BALANCES_TO_CONTROLLER");
    } else {
      // If selling UP
      uint256 darbiBalanceMaximumUpToMint = balances / backedValue; // Amount of UP that we can mint with current balances
      actualAmountIn = amountIn <= darbiBalanceMaximumUpToMint
        ? amountIn
        : darbiBalanceMaximumUpToMint; // Value in UP
      uint256 nativeToMint = actualAmountIn / backedValue;
      DARBI_MINTER.mintUP{value: nativeToMint}();

      path[0] = UP_TOKEN;
      path[1] = WETH;
      router.swapExactTokensForETH(
        IERC20(UP_TOKEN).balanceOf(address(this)),
        0,
        path,
        address(this),
        block.timestamp + 20 minutes
      );
      uint256 diffBalances = address(this).balance - balances;
      (bool success, ) = address(UP_CONTROLLER).call{value: diffBalances}("");
      require(success, "FAIL_SENDING_BALANCES_TO_CONTROLLER");
      //This Sells UP
    }
  }

  function moveMarketBuyAmount() public view returns (bool aToB, uint256 amountIn) {
    address UP_TOKEN = UP_CONTROLLER.UP_TOKEN();
    address[2] memory swappedTokens = [UP_TOKEN, address(WETH)];
    (uint256 reserves0, uint256 reserves1) = UniswapHelper.getReserves(
      factory,
      swappedTokens[0],
      swappedTokens[1]
    );
    uint256 upPrice = UP_CONTROLLER.getVirtualPrice();
    (aToB, amountIn) = UniswapHelper.computeTradeToMoveMarket(
      1000000000000000000, // Ratio = 1:UPVirtualPrice
      upPrice,
      reserves0,
      reserves1
    );
    return (aToB, amountIn);
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
