# Solidity API

## UniswapV2LiquidityMathLibrary

### computeProfitMaximizingTrade

```solidity
function computeProfitMaximizingTrade(uint256 truePriceTokenA, uint256 truePriceTokenB, uint256 reserveA, uint256 reserveB) internal pure returns (bool aToB, uint256 amountIn)
```

### getReservesAfterArbitrage

```solidity
function getReservesAfterArbitrage(address factory, address tokenA, address tokenB, uint256 truePriceTokenA, uint256 truePriceTokenB) internal view returns (uint256 reserveA, uint256 reserveB)
```

### computeLiquidityValue

```solidity
function computeLiquidityValue(uint256 reservesA, uint256 reservesB, uint256 totalSupply, uint256 liquidityAmount, bool feeOn, uint256 kLast) internal pure returns (uint256 tokenAAmount, uint256 tokenBAmount)
```

### getLiquidityValue

```solidity
function getLiquidityValue(address factory, address tokenA, address tokenB, uint256 liquidityAmount) internal view returns (uint256 tokenAAmount, uint256 tokenBAmount)
```

### getLiquidityValueAfterArbitrageToPrice

```solidity
function getLiquidityValueAfterArbitrageToPrice(address factory, address tokenA, address tokenB, uint256 truePriceTokenA, uint256 truePriceTokenB, uint256 liquidityAmount) internal view returns (uint256 tokenAAmount, uint256 tokenBAmount)
```

