# Solidity API

## Rebalancer

### STAKING_ROLE

```solidity
bytes32 STAKING_ROLE
```

### WETH

```solidity
address WETH
```

### UPaddress

```solidity
address UPaddress
```

### strategy

```solidity
address strategy
```

### unifiRouter

```solidity
address unifiRouter
```

### liquidityPool

```solidity
address liquidityPool
```

### UP_CONTROLLER

```solidity
address payable UP_CONTROLLER
```

### distribution

```solidity
uint256[3] distribution
```

### onlyStaking

```solidity
modifier onlyStaking()
```

### onlyAdmin

```solidity
modifier onlyAdmin()
```

### constructor

```solidity
constructor(address _WETH, address _UPAddress, address _UPController, address _Strategy, address _unifiRouter, address _liquidityPool) public
```

### receive

```solidity
receive() external payable
```

### rebalance

```solidity
function rebalance() public
```

### _distribution1

```solidity
function _distribution1(uint256 _amount) internal
```

### _distribution2

```solidity
function _distribution2(uint256 _amount) internal
```

### _distribution3

```solidity
function _distribution3(uint256 _amount) internal
```

### setDistribution

```solidity
function setDistribution(uint256[3] _distribution) public
```

### setUPController

```solidity
function setUPController(address newAddress) public
```

### setStrategy

```solidity
function setStrategy(address newAddress) public
```

### setUnifiRouter

```solidity
function setUnifiRouter(address newAddress) public
```

### withdrawFunds

```solidity
function withdrawFunds(address target) public returns (bool)
```

### withdrawFundsERC20

```solidity
function withdrawFundsERC20(address target, address tokenAddress) public returns (bool)
```

### pause

```solidity
function pause() public
```

Permissioned function to pause UPaddress Controller

### unpause

```solidity
function unpause() public
```

Permissioned function to unpause UPaddress Controller

## Rebalancer

### STAKING_ROLE

```solidity
bytes32 STAKING_ROLE
```

### WETH

```solidity
address WETH
```

### UPaddress

```solidity
address UPaddress
```

### strategy

```solidity
address strategy
```

### unifiRouter

```solidity
address unifiRouter
```

### liquidityPool

```solidity
address liquidityPool
```

### UP_CONTROLLER

```solidity
address payable UP_CONTROLLER
```

### distribution

```solidity
uint256[3] distribution
```

### onlyStaking

```solidity
modifier onlyStaking()
```

### onlyAdmin

```solidity
modifier onlyAdmin()
```

### constructor

```solidity
constructor(address _WETH, address _UPAddress, address _UPController, address _Strategy, address _unifiRouter, address _liquidityPool) public
```

### receive

```solidity
receive() external payable
```

### rebalance

```solidity
function rebalance() public
```

### _distribution1

```solidity
function _distribution1(uint256 _amount) internal
```

### _distribution2

```solidity
function _distribution2(uint256 _amount) internal
```

### _distribution3

```solidity
function _distribution3(uint256 _amount) internal
```

### setDistribution

```solidity
function setDistribution(uint256[3] _distribution) public
```

### setUPController

```solidity
function setUPController(address newAddress) public
```

### setStrategy

```solidity
function setStrategy(address newAddress) public
```

### setUnifiRouter

```solidity
function setUnifiRouter(address newAddress) public
```

### withdrawFunds

```solidity
function withdrawFunds(address target) public returns (bool)
```

### withdrawFundsERC20

```solidity
function withdrawFundsERC20(address target, address tokenAddress) public returns (bool)
```

### pause

```solidity
function pause() public
```

Permissioned function to pause UPaddress Controller

### unpause

```solidity
function unpause() public
```

Permissioned function to unpause UPaddress Controller

## Rebalancer

### STAKING_ROLE

```solidity
bytes32 STAKING_ROLE
```

### WETH

```solidity
address WETH
```

### UPaddress

```solidity
address UPaddress
```

### strategy

```solidity
address strategy
```

### unifiRouter

```solidity
address unifiRouter
```

### liquidityPool

```solidity
address liquidityPool
```

### UP_CONTROLLER

```solidity
address payable UP_CONTROLLER
```

### distribution

```solidity
uint256[3] distribution
```

### onlyStaking

```solidity
modifier onlyStaking()
```

### onlyAdmin

```solidity
modifier onlyAdmin()
```

### constructor

```solidity
constructor(address _WETH, address _UPAddress, address _UPController, address _Strategy, address _unifiRouter, address _liquidityPool) public
```

### receive

```solidity
receive() external payable
```

### rebalance

```solidity
function rebalance() public
```

### _distribution1

```solidity
function _distribution1(uint256 _amount) internal
```

### _distribution2

```solidity
function _distribution2(uint256 _amount) internal
```

### _distribution3

```solidity
function _distribution3(uint256 _amount) internal
```

### setDistribution

```solidity
function setDistribution(uint256[3] _distribution) public
```

### setUPController

```solidity
function setUPController(address newAddress) public
```

### setStrategy

```solidity
function setStrategy(address newAddress) public
```

### setUnifiRouter

```solidity
function setUnifiRouter(address newAddress) public
```

### withdrawFunds

```solidity
function withdrawFunds(address target) public returns (bool)
```

### withdrawFundsERC20

```solidity
function withdrawFundsERC20(address target, address tokenAddress) public returns (bool)
```

### pause

```solidity
function pause() public
```

Permissioned function to pause UPaddress Controller

### unpause

```solidity
function unpause() public
```

Permissioned function to unpause UPaddress Controller

## Rebalancer

### WETH

```solidity
address WETH
```

### UP

```solidity
address UP
```

### liquidityPool

```solidity
address liquidityPool
```

### distribution

```solidity
uint256[3] distribution
```

### constructor

```solidity
constructor(address _WETH, address _UP, address _liquidityPool) public
```

### setDistribution

```solidity
function setDistribution(uint256[3] _distribution) public
```

### setUPToken

```solidity
function setUPToken(address newAddress) public
```

### setLiquidityPool

```solidity
function setLiquidityPool(address newAddress) public
```

### withdrawFunds

```solidity
function withdrawFunds(address target) public returns (bool)
```

### withdrawFundsERC20

```solidity
function withdrawFundsERC20(address target, address tokenAddress) public returns (bool)
```

