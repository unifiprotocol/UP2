# Solidity API

## UPProxy

### UP_TOKEN

```solidity
address UP_TOKEN
```

### UP_CONTROLLER

```solidity
address UP_CONTROLLER
```

### constructor

```solidity
constructor(address _UP, address _UP_CONTROLLER) public
```

### receive

```solidity
receive() external payable
```

_Fallback function that delegates calls to the address returned by &#x60;_implementation()&#x60;. Will run if call data
is empty._

### mint

```solidity
function mint(address to, uint256 value) public payable returns (bool)
```

### _implementation

```solidity
function _implementation() internal view returns (address)
```

_This is a virtual function that should be overridden so it returns the address to which the fallback function
and {_fallback} should delegate._

### setController

```solidity
function setController(address newAddress) public
```

### withdrawFunds

```solidity
function withdrawFunds(address target) public returns (bool)
```

### withdrawFundsERC20

```solidity
function withdrawFundsERC20(address target, address tokenAddress) public returns (bool)
```

