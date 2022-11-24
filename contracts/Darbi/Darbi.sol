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
import "../Strategies/Strategy.sol";

contract Darbi is AccessControl, Pausable, Safe {
  using SafeERC20 for IERC20;

  bytes32 public constant REBALANCER_ROLE = keccak256("REBALANCER_ROLE");

  address public factory;
  address public WETH;
  address public rebalancer;
  bool public fundingFromStrategy; // if True, Darbi funding comes from Strategy. If false, Darbi funding comes from Controller.
  bool public strategyLockup; // if True, funds in Strategy are cannot be withdrawn immediately (such as staking on Harmony). If false, funds in Strategy are always available (such as AAVE on Polygon).
  IERC20 public UP_TOKEN;
  IUniswapV2Router02 public router;
  UPController public UP_CONTROLLER;
  UPMintDarbi public DARBI_MINTER;
  Strategy public STRATEGY;

  event Arbitrage(bool isSellingUp, uint256 actualAmountIn);

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Darbi: ONLY_ADMIN");
    _;
  }

  modifier onlyRebalancer() {
    require(hasRole(REBALANCER_ROLE, msg.sender), "Darbi: ONLY_REBALANCER");
    _;
  }

  constructor(
    address _factory,
    address _router,
    address _strategy,
    address _WETH,
    address _rebalancer,
    address _UP_CONTROLLER,
    address _darbiMinter,
    address _fundsTarget
  ) Safe(_fundsTarget) {
    factory = _factory;
    router = IUniswapV2Router02(_router);
    STRATEGY = Strategy(payable(_strategy));
    WETH = _WETH;
    rebalancer = payable(_rebalancer);
    UP_CONTROLLER = UPController(payable(_UP_CONTROLLER));
    DARBI_MINTER = UPMintDarbi(payable(_darbiMinter));
    UP_TOKEN = IERC20(payable(UP_CONTROLLER.UP_TOKEN()));
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  receive() external payable {}

  function _checkAvailableFunds() internal view returns (uint256 fundsAvailable) {
    if (fundingFromStrategy == true) {
      if (strategyLockup == true) {
        fundsAvailable = address(STRATEGY).balance;
      } else {
        fundsAvailable = Strategy(STRATEGY).amountDeposited();
      }
    } else {
      fundsAvailable = (address(UP_CONTROLLER).balance / 3);
    }
    return fundsAvailable;
  }

  function arbitrage() public whenNotPaused returns (uint256 profit) {
    (
      bool aToB,
      uint256 amountIn, //if buying UP, number returned is in native value. If selling UP, number returned in UP value.
      uint256 reserves0,
      uint256 reserves1,
      uint256 backedValue
    ) = moveMarketBuyAmount();

    // aToB == true == Buys UP
    // aToB == fals == Sells UP
    uint256 fundsAvailable = _checkAvailableFunds();
    uint256 tradeSize;
    uint256 actualAmountIn;
    // If Buying UP
    if (!aToB) {
      actualAmountIn == amountIn;
      while (actualAmountIn > 0) {
        if (actualAmountIn > fundsAvailable) {
          tradeSize = fundsAvailable;
          actualAmountIn -= tradeSize;
        } else {
          tradeSize = actualAmountIn;
          actualAmountIn == 0;
        }

        uint256 expectedReturn = UniswapHelper.getAmountOut(tradeSize, reserves1, reserves0); // Amount of UP expected from Buy
        uint256 expectedNativeReturn = (expectedReturn * backedValue) / 1e18; //Amount of Native Tokens Expected to Receive from Redeem
        uint256 upControllerBalance = address(UP_CONTROLLER).balance;

        if (upControllerBalance < expectedNativeReturn) {
          uint256 upOutput = (upControllerBalance * 1e18) / backedValue; //Value in UP Token
          tradeSize = UniswapHelper.getAmountIn(upOutput, reserves1, reserves0);
          actualAmountIn += (tradeSize - upOutput); // Amount of UP expected from Buy
        }

        if (fundingFromStrategy == true) {
          IStrategy(address(STRATEGY)).withdraw(tradeSize);
        } else {
          UPController(UP_CONTROLLER).borrowNative(tradeSize, address(this));
        }
        _arbitrageBuy(tradeSize);
        if (fundingFromStrategy == true) {
          IStrategy(address(STRATEGY)).deposit(tradeSize);
        } else {
          UPController(UP_CONTROLLER).repay{value: tradeSize}(0);
        }
      }
    } else {
      // If Selling Up
      while (
        amountIn > 100 //allows for dust + rounding of 100 gwei of UP
      ) {
        actualAmountIn = amountIn *= backedValue;
        if (actualAmountIn > fundsAvailable) {
          tradeSize = fundsAvailable;
          actualAmountIn -= tradeSize;
        } else {
          tradeSize = actualAmountIn;
          actualAmountIn == 0;
        }
        if (fundingFromStrategy == true) {
          IStrategy(address(STRATEGY)).withdraw(tradeSize);
        } else {
          UPController(UP_CONTROLLER).borrowNative(tradeSize, address(this));
        }
        uint256 upSold = _arbitrageSell(tradeSize);
        amountIn -= upSold;
        if (fundingFromStrategy == true) {
          IStrategy(address(STRATEGY)).deposit(tradeSize);
        } else {
          UPController(UP_CONTROLLER).repay{value: tradeSize}(0);
        }
      }
    }
    profit == refund();
    return profit;
  }

  function forceArbitrage() public whenNotPaused onlyRebalancer {
    arbitrage();
  } //Function preserved for Rebalancer

  function _arbitrageBuy(uint256 amountIn) internal {
    address[] memory path = new address[](2);
    path[0] = WETH;
    path[1] = address(UP_TOKEN);

    uint256[] memory amounts = router.swapExactETHForTokens{value: amountIn}(
      0,
      path,
      address(this),
      block.timestamp + 150
    );

    UP_TOKEN.approve(address(UP_CONTROLLER), amounts[1]);
    UP_CONTROLLER.redeem(amounts[1]);

    emit Arbitrage(false, amountIn);
  }

  function _arbitrageSell(uint256 tradeSize) internal returns (uint256 up2Balance) {
    // If selling UP
    DARBI_MINTER.mintUP{value: tradeSize}();

    address[] memory path = new address[](2);
    path[0] = address(UP_TOKEN);
    path[1] = WETH;

    up2Balance = UP_TOKEN.balanceOf(address(this));
    UP_TOKEN.approve(address(router), up2Balance);
    router.swapExactTokensForETH(up2Balance, 0, path, address(this), block.timestamp + 150);

    emit Arbitrage(true, up2Balance);
  }

  function refund() public whenNotPaused returns (uint256 proceeds) {
    proceeds = address(this).balance;
    if (msg.sender == rebalancer) {
      UPController(UP_CONTROLLER).repay{value: proceeds}(0);
    } else {
      (bool success2, ) = (msg.sender).call{value: proceeds}("");
      require(success2, "Darbi: FAIL_SENDING_PROFITS_TO_CALLER");
    }
    return proceeds;
  }

  function moveMarketBuyAmount()
    public
    view
    returns (
      bool aToB,
      uint256 amountIn,
      uint256 reservesUP,
      uint256 reservesETH,
      uint256 upPrice
    )
  {
    (reservesUP, reservesETH) = UniswapHelper.getReserves(
      factory,
      address(UP_TOKEN),
      address(WETH)
    );
    upPrice = UP_CONTROLLER.getVirtualPrice();

    (aToB, amountIn) = UniswapHelper.computeTradeToMoveMarket(
      1000000000000000000, // Ratio = 1:UPVirtualPrice
      upPrice,
      reservesUP,
      reservesETH
    );
    return (aToB, amountIn, reservesUP, reservesETH, upPrice);
  }

  function redeemUP() internal {
    UP_CONTROLLER.redeem(IERC20(UP_CONTROLLER.UP_TOKEN()).balanceOf(address(this)));
  }

  function setController(address _controller) public onlyAdmin {
    require(_controller != address(0));
    UP_CONTROLLER = UPController(payable(_controller));
  }

  function setDarbiMinter(address _newMinter) public onlyAdmin {
    require(_newMinter != address(0));
    DARBI_MINTER = UPMintDarbi(payable(_newMinter));
  }

  function setFundingFromStrategy(bool isTrue) public onlyAdmin {
    fundingFromStrategy = isTrue;
  }

  function setStrategyLockup(bool isTrue) public onlyAdmin {
    strategyLockup = isTrue;
  }

  function withdrawFunds() public onlyAdmin returns (bool) {
    return _withdrawFunds();
  }

  function withdrawFundsERC20(address tokenAddress) public onlyAdmin returns (bool) {
    return _withdrawFundsERC20(tokenAddress);
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
