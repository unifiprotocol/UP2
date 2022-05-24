# Solidity API

## Strategy

### receive

```solidity
receive() external payable virtual
```

### deposit

```solidity
function deposit(uint256 amount) external returns (bool)
```

Deposits an initial or more liquidity in the external contract

### withdraw

```solidity
function withdraw(uint256 amount) external returns (bool)
```

Withdraws all the funds deposited in the external contract

### gather

```solidity
function gather() public
```

This function will get all the rewards from the external service and send them to the invoker

### withdrawFunds

```solidity
function withdrawFunds(address target) public returns (bool)
```

### withdrawFundsERC20

```solidity
function withdrawFundsERC20(address target, address tokenAddress) public returns (bool)
```

## Strategy

### receive

```solidity
receive() external payable virtual
```

### deposit

```solidity
function deposit(uint256 amount) external returns (bool)
```

Deposits an initial or more liquidity in the external contract

### withdraw

```solidity
function withdraw(uint256 amount) external returns (bool)
```

Withdraws all the funds deposited in the external contract

### gather

```solidity
function gather() public
```

This function will get all the rewards from the external service and send them to the invoker

### withdrawFunds

```solidity
function withdrawFunds(address target) public returns (bool)
```

### withdrawFundsERC20

```solidity
function withdrawFundsERC20(address target, address tokenAddress) public returns (bool)
```

