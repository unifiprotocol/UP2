# Solidity API

## Darbi

### router

```solidity
contract IUniswapV2Router02 router
```

### factory

```solidity
address factory
```

### admins

```solidity
mapping(address &#x3D;&gt; bool) admins
```

### onlyAdmin

```solidity
modifier onlyAdmin()
```

### constructor

```solidity
constructor(address _factory, address _router) public
```

### swapToPrice

```solidity
function swapToPrice(address tokenA, address tokenB, uint256 truePriceTokenA, uint256 truePriceTokenB, uint256 maxSpendTokenA, uint256 maxSpendTokenB, address to, uint256 deadline) public
```

### setAdmin

```solidity
function setAdmin(address _newAdmin) public
```

### removeAdmin

```solidity
function removeAdmin(address _adminAddr) public
```

