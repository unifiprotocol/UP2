# Solidity API

## Vendor

Swaps 1:1 between UP tokens - Needs to be top up first.

### OLD_UP

```solidity
address OLD_UP
```

### UP

```solidity
address UP
```

### Swap

```solidity
event Swap(address _from, uint256 _amount)
```

### constructor

```solidity
constructor(address oldUp, address newUp) public
```

### swap

```solidity
function swap(uint256 _amount) public
```

Giving an amount of tokens, will swap between them

| Name | Type | Description |
| ---- | ---- | ----------- |
| _amount | uint256 | Amount to be swapped |

### balance

```solidity
function balance() public view returns (uint256)
```

### pause

```solidity
function pause() public
```

### unpause

```solidity
function unpause() public
```

### withdrawFundsERC20

```solidity
function withdrawFundsERC20(address target, address tokenAddress) public returns (bool)
```

## Vendor

### OLD_UP

```solidity
address OLD_UP
```

### UP

```solidity
address UP
```

### Swap

```solidity
event Swap(address _from, uint256 _amount)
```

### constructor

```solidity
constructor(address oldUp, address newUp) public
```

### swap

```solidity
function swap(uint256 _amount) public
```

### balance

```solidity
function balance() public view returns (uint256)
```

### pause

```solidity
function pause() public
```

### unpause

```solidity
function unpause() public
```

### withdrawFundsERC20

```solidity
function withdrawFundsERC20(address target, address tokenAddress) public returns (bool)
```

