# Solidity API

## AAVE

This controller deposits the native tokens backing UP into the AAVE Supply Pool, and triggers the Rebalancer

### rebalancer

```solidity
address rebalancer
```

### amountDeposited

```solidity
uint256 amountDeposited
```

### UpdateRebalancer

```solidity
event UpdateRebalancer(address _rebalancer)
```

### TriggerRebalance

```solidity
event TriggerRebalance(uint256 amountClaimed)
```

### constructor

```solidity
constructor(address _rebalancer) public
```

### updateRebalancer

```solidity
function updateRebalancer(address _rebalancer) public
```

Permissioned function to update the address of the Rebalancer

| Name | Type | Description |
| ---- | ---- | ----------- |
| _rebalancer | address | - the address of the new rebalancer |

## AAVE

This controller deposits the native tokens backing UP into the AAVE Supply Pool, and triggers the Rebalancer

### rebalancer

```solidity
address rebalancer
```

### amountDeposited

```solidity
uint256 amountDeposited
```

### wrappedTokenAddress

```solidity
address wrappedTokenAddress
```

### aaveIncentivesController

```solidity
address aaveIncentivesController
```

### UpdateRebalancer

```solidity
event UpdateRebalancer(address _rebalancer)
```

### TriggerRebalance

```solidity
event TriggerRebalance(uint256 amountClaimed)
```

### constructor

```solidity
constructor(address _rebalancer, address _wrappedTokenAddress, address _aaveIncentivesController) public
```

### updateRebalancer

```solidity
function updateRebalancer(address _rebalancer) public
```

Permissioned function to update the address of the Rebalancer

| Name | Type | Description |
| ---- | ---- | ----------- |
| _rebalancer | address | - the address of the new rebalancer |

