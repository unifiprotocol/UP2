// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "@uniswap/lib/contracts/libraries/Babylonian.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../Libraries/UniswapHelper.sol";
import "../Helpers/Safe.sol";
import "../UPController.sol";
import "./UPMintDarbi.sol";

contract Darbi is AccessControl, Pausable, Safe {
  using SafeERC20 for IERC20;

  bytes32 public constant MONITOR_ROLE = keccak256("MONITOR_ROLE");
  bytes32 public constant REBALANCER_ROLE = keccak256("REBALANCER_ROLE");

  address public factory;
  address public WETH;
  address public gasRefundAddress;
  uint256 public arbitrageThreshold = 100000;
  uint256 public gasRefund = 3500000000000000;
  uint256 public darbiDepositBalance = 0;
  IERC20 public UP_TOKEN;
  IUniswapV2Router02 public router;
  UPController public UP_CONTROLLER;
  UPMintDarbi public DARBI_MINTER;

  event Arbitrage(bool isSellingUp, uint256 actualAmountIn);

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ONLY_ADMIN");
    _;
  }

  modifier onlyMonitor() {
    require(hasRole(MONITOR_ROLE, msg.sender), "ONLY_MONITOR");
    _;
  }

  modifier onlyRebalancer() {
    require(hasRole(REBALANCER_ROLE, msg.sender), "ONLY_REBALANCER");
    _;
  }

  modifier onlyRebalancerOrMonitor() {
    require(
      hasRole(REBALANCER_ROLE, msg.sender) || hasRole(MONITOR_ROLE, msg.sender),
      "ONLY_REBALANCER_OR_MONITOR"
    );
    _;
  }

  constructor(
    address _factory,
    address _router,
    address _WETH,
    address _gasRefundAddress,
    address _UP_CONTROLLER,
    address _darbiMinter,
    uint256 _arbitrageThreshold
  ) {
    factory = _factory;
    router = IUniswapV2Router02(_router);
    WETH = _WETH;
    gasRefundAddress = _gasRefundAddress;
    UP_CONTROLLER = UPController(payable(_UP_CONTROLLER));
    DARBI_MINTER = UPMintDarbi(payable(_darbiMinter));
    UP_TOKEN = IERC20(payable(UP_CONTROLLER.UP_TOKEN()));
    arbitrageThreshold = _arbitrageThreshold;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MONITOR_ROLE, msg.sender);
    _setupRole(REBALANCER_ROLE, msg.sender);
  }

  receive() external payable {}

  function arbitrage() public whenNotPaused onlyMonitor {
    (
      bool aToB,
      uint256 amountIn,
      uint256 reserves0,
      uint256 reserves1,
      uint256 backedValue
    ) = moveMarketBuyAmount();

    // aToB == true == Buys UP
    // aToB == fals == Sells UP
    uint256 balances = address(this).balance;
    // If Buying UP
    if (!aToB) {
      require(amountIn > gasRefund, "Trade will not be profitable");
      if (amountIn > arbitrageThreshold) return;
      _arbitrageBuy(balances, amountIn, backedValue, reserves0, reserves1);
    } else {
      uint256 amountInETHTerms = (amountIn * backedValue) / 1e18;
      require(amountInETHTerms > gasRefund, "Trade will not be profitable");
      if (amountInETHTerms > arbitrageThreshold) return;
      _arbitrageSell(balances, amountIn, backedValue);
    }
  }

  function forceArbitrage() public whenNotPaused onlyRebalancer {
    (
      bool aToB,
      uint256 amountIn,
      uint256 reserves0,
      uint256 reserves1,
      uint256 backedValue
    ) = moveMarketBuyAmount();

    // aToB == true == Buys UP
    // aToB == fals == Sells UP
    uint256 balances = address(this).balance;
    // If Buying UP
    if (!aToB) {
      if (amountIn > arbitrageThreshold) return;
      _arbitrageBuy(balances, amountIn, backedValue, reserves0, reserves1);
    } else {
      uint256 amountInETHTerms = (amountIn * backedValue) / 1e18;
      if (amountInETHTerms > arbitrageThreshold) return;
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

    uint256[] memory amounts = router.swapExactETHForTokens{value: actualAmountIn}(
      0,
      path,
      address(this),
      block.timestamp + 150
    );

    UP_TOKEN.approve(address(UP_CONTROLLER), amounts[1]);
    UP_CONTROLLER.redeem(amounts[1]);

    refund();

    emit Arbitrage(false, actualAmountIn);
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

    refund();

    emit Arbitrage(true, up2Balance);
  }

  function refund() public whenNotPaused onlyRebalancerOrMonitor {
    uint256 newBalances = address(this).balance;
    if ((newBalances + gasRefund) < darbiDepositBalance) return;
    (bool success1, ) = gasRefundAddress.call{value: gasRefund}("");
    require(success1, "FAIL_SENDING_GAS_REFUND_TO_MONITOR");
    uint256 diffBalances = newBalances - darbiDepositBalance - gasRefund;
    (bool success2, ) = address(UP_CONTROLLER).call{value: diffBalances}("");
    require(success2, "FAIL_SENDING_BALANCES_TO_CONTROLLER");
  }

  function moveMarketBuyAmount()
    public
    view
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

  function addDarbiFunds() public payable {
    uint256 depositAmount = msg.value;
    darbiDepositBalance += depositAmount;
  }

  function redeemUP() internal {
    UP_CONTROLLER.redeem(IERC20(UP_CONTROLLER.UP_TOKEN()).balanceOf(address(this)));
  }

  function setController(address _controller) public onlyAdmin {
    require(_controller != address(0));
    UP_CONTROLLER = UPController(payable(_controller));
  }

  function setDarbiFunds(uint256 setAmount) public onlyAdmin {
    darbiDepositBalance = setAmount;
  }

  function setArbitrageThreshold(uint256 _threshold) public onlyAdmin {
    require(_threshold > 0);
    arbitrageThreshold = _threshold;
  }

  function setGasRefund(uint256 _gasRefund) public onlyAdmin {
    require(_gasRefund > 0);
    gasRefund = _gasRefund;
  }

  function setGasRefundAddress(address _gasRefundAddress) public onlyAdmin {
    require(_gasRefundAddress != address(0));
    gasRefundAddress = _gasRefundAddress;
  }

  function setDarbiMinter(address _newMinter) public onlyAdmin {
    require(_newMinter != address(0));
    DARBI_MINTER = UPMintDarbi(payable(_newMinter));
  }

  function withdrawFunds(address target) public onlyAdmin returns (bool) {
    darbiDepositBalance == 0;
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
