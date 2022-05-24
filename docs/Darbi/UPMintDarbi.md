# Solidity API

## UPMintDarbi

This contract is for the public minting of UP token, allowing users to deposit native tokens and receive UP tokens.

### DARBI_ROLE

```solidity
bytes32 DARBI_ROLE
```

### mintRate

```solidity
uint256 mintRate
```

### UP_TOKEN

```solidity
address UP_TOKEN
```

### DARBI

```solidity
address DARBI
```

### UP_CONTROLLER

```solidity
address payable UP_CONTROLLER
```

### onlyDarbi

```solidity
modifier onlyDarbi()
```

### onlyAdmin

```solidity
modifier onlyAdmin()
```

### NewDarbiMintRate

```solidity
event NewDarbiMintRate(uint256 _newMintRate)
```

### DarbiMint

```solidity
event DarbiMint(address _from, uint256 _amount, uint256 _price, uint256 _value)
```

### UpdateController

```solidity
event UpdateController(address _upController)
```

### constructor

```solidity
constructor(address _UP, address _UPController, uint256 _mintRate) public
```

### mintUP

```solidity
function mintUP() public payable
```

Payable function that mints UP at the mint rate, deposits the native tokens to the UP Controller, Sends UP to the Msg.sender

### setMintRate

```solidity
function setMintRate(uint256 _mintRate) public
```

Permissioned function that sets the public rint of UP.

| Name | Type | Description |
| ---- | ---- | ----------- |
| _mintRate | uint256 | - mint rate in percent texrms, _mintRate &#x3D; 5 &#x3D; 5%. |

### updateController

```solidity
function updateController(address _upController) public
```

Permissioned function to update the address of the UP Controller

| Name | Type | Description |
| ---- | ---- | ----------- |
| _upController | address | - the address of the new UP Controller |

### pause

```solidity
function pause() public
```

Permissioned function to pause Darbi minting

### unpause

```solidity
function unpause() public
```

Permissioned function to unpause Darbi minting

### withdrawFunds

```solidity
function withdrawFunds(address target) public returns (bool)
```

Permissioned function to withdraw any native coins accidentally deposited to the Darbi Mint contract.

### withdrawFundsERC20

```solidity
function withdrawFundsERC20(address target, address tokenAddress) public returns (bool)
```

Permissioned function to withdraw any tokens accidentally deposited to the Darbi Mint contract.

### fallback

```solidity
fallback() external payable
```

### receive

```solidity
receive() external payable
```

## UPMintDarbi

This contract is for the public minting of UP token, allowing users to deposit native tokens and receive UP tokens.

### DARBI_ROLE

```solidity
bytes32 DARBI_ROLE
```

### mintRate

```solidity
uint256 mintRate
```

### UP_TOKEN

```solidity
address UP_TOKEN
```

### DARBI

```solidity
address DARBI
```

### UP_CONTROLLER

```solidity
address payable UP_CONTROLLER
```

### onlyDarbi

```solidity
modifier onlyDarbi()
```

### onlyAdmin

```solidity
modifier onlyAdmin()
```

### NewDarbiMintRate

```solidity
event NewDarbiMintRate(uint256 _newMintRate)
```

### DarbiMint

```solidity
event DarbiMint(address _from, uint256 _amount, uint256 _price, uint256 _value)
```

### UpdateController

```solidity
event UpdateController(address _upController)
```

### constructor

```solidity
constructor(address _UP, address _UPController, uint256 _mintRate) public
```

### mintUP

```solidity
function mintUP() public payable
```

Payable function that mints UP at the mint rate, deposits the native tokens to the UP Controller, Sends UP to the Msg.sender

### setMintRate

```solidity
function setMintRate(uint256 _mintRate) public
```

Permissioned function that sets the public rint of UP.

| Name | Type | Description |
| ---- | ---- | ----------- |
| _mintRate | uint256 | - mint rate in percent texrms, _mintRate &#x3D; 5 &#x3D; 5%. |

### updateController

```solidity
function updateController(address _upController) public
```

Permissioned function to update the address of the UP Controller

| Name | Type | Description |
| ---- | ---- | ----------- |
| _upController | address | - the address of the new UP Controller |

### pause

```solidity
function pause() public
```

Permissioned function to pause Darbi minting

### unpause

```solidity
function unpause() public
```

Permissioned function to unpause Darbi minting

### withdrawFunds

```solidity
function withdrawFunds(address target) public returns (bool)
```

Permissioned function to withdraw any native coins accidentally deposited to the Darbi Mint contract.

### withdrawFundsERC20

```solidity
function withdrawFundsERC20(address target, address tokenAddress) public returns (bool)
```

Permissioned function to withdraw any tokens accidentally deposited to the Darbi Mint contract.

### fallback

```solidity
fallback() external payable
```

### receive

```solidity
receive() external payable
```

