# Solidity API

## UPMintPublic

This contract is for the public minting of UP token, allowing users to deposit native tokens and receive UP tokens.

### mintRate

```solidity
uint256 mintRate
```

### UP_TOKEN

```solidity
address UP_TOKEN
```

### UP_CONTROLLER

```solidity
address payable UP_CONTROLLER
```

### NewPublicMintRate

```solidity
event NewPublicMintRate(uint256 _newMintRate)
```

### PublicMint

```solidity
event PublicMint(address _from, uint256 _amount, uint256 _price, uint256 _value)
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

Permissioned function to pause public minting

### unpause

```solidity
function unpause() public
```

Permissioned function to unpause public minting

### withdrawFunds

```solidity
function withdrawFunds(address target) public returns (bool)
```

Permissioned function to withdraw any native coins accidentally deposited to the Public Mint contract.

### withdrawFundsERC20

```solidity
function withdrawFundsERC20(address target, address tokenAddress) public returns (bool)
```

Permissioned function to withdraw any tokens accidentally deposited to the Public Mint contract.

## UPMintPublic

This contract is for the public minting of UP token, allowing users to deposit native tokens and receive UP tokens.

### mintRate

```solidity
uint256 mintRate
```

### UP_TOKEN

```solidity
address UP_TOKEN
```

### UP_CONTROLLER

```solidity
address payable UP_CONTROLLER
```

### NewPublicMintRate

```solidity
event NewPublicMintRate(uint256 _newMintRate)
```

### PublicMint

```solidity
event PublicMint(address _from, address _to, uint256 _amount, uint256 _price, uint256 _value)
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
function mintUP(address to) public payable
```

Payable function that mints UP at the mint rate, deposits the native tokens to the UP Controller, Sends UP to the Msg.sender

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | Destination address for minted tokens |

### setMintRate

```solidity
function setMintRate(uint256 _mintRate) public
```

Permissioned function that sets the public rint of UP.

| Name | Type | Description |
| ---- | ---- | ----------- |
| _mintRate | uint256 | - mint rate in percent terms, _mintRate &#x3D; 5 &#x3D; 5%. |

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

Permissioned function to pause public minting

### unpause

```solidity
function unpause() public
```

Permissioned function to unpause public minting

### withdrawFunds

```solidity
function withdrawFunds(address target) public returns (bool)
```

Permissioned function to withdraw any native coins accidentally deposited to the Public Mint contract.

### withdrawFundsERC20

```solidity
function withdrawFundsERC20(address target, address tokenAddress) public returns (bool)
```

Permissioned function to withdraw any tokens accidentally deposited to the Public Mint contract.

## UPMintPublic

This contract is for the public minting of UP token, allowing users to deposit native tokens and receive UP tokens.

### mintRate

```solidity
uint256 mintRate
```

### UP_TOKEN

```solidity
address UP_TOKEN
```

### UP_CONTROLLER

```solidity
address payable UP_CONTROLLER
```

### NewPublicMintRate

```solidity
event NewPublicMintRate(uint256 _newMintRate)
```

### PublicMint

```solidity
event PublicMint(address _from, address _to, uint256 _amount, uint256 _price, uint256 _value)
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
function mintUP(address to) public payable
```

Payable function that mints UP at the mint rate, deposits the native tokens to the UP Controller, Sends UP to the Msg.sender

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | Destination address for minted tokens |

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

Permissioned function to pause public minting

### unpause

```solidity
function unpause() public
```

Permissioned function to unpause public minting

### withdrawFunds

```solidity
function withdrawFunds(address target) public returns (bool)
```

Permissioned function to withdraw any native coins accidentally deposited to the Public Mint contract.

### withdrawFundsERC20

```solidity
function withdrawFundsERC20(address target, address tokenAddress) public returns (bool)
```

Permissioned function to withdraw any tokens accidentally deposited to the Public Mint contract.

## UPMintPublic

This contract is for the public minting of UP token, allowing users to deposit native tokens and receive UP tokens.

### mintRate

```solidity
uint256 mintRate
```

### UP_TOKEN

```solidity
address UP_TOKEN
```

### UP_CONTROLLER

```solidity
address payable UP_CONTROLLER
```

### NewPublicMintRate

```solidity
event NewPublicMintRate(uint256 _newMintRate)
```

### PublicMint

```solidity
event PublicMint(address _from, address _to, uint256 _amount, uint256 _price, uint256 _value)
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
function mintUP(address to) public payable
```

Payable function that mints UP at the mint rate, deposits the native tokens to the UP Controller, Sends UP to the Msg.sender

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | Destination address for minted tokens |

### setMintRate

```solidity
function setMintRate(uint256 _mintRate) public
```

Permissioned function that sets the public rint of UP.

| Name | Type | Description |
| ---- | ---- | ----------- |
| _mintRate | uint256 | - mint rate in percent terms, _mintRate &#x3D; 5 &#x3D; 5%. |

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

Permissioned function to pause public minting

### unpause

```solidity
function unpause() public
```

Permissioned function to unpause public minting

### withdrawFunds

```solidity
function withdrawFunds(address target) public returns (bool)
```

Permissioned function to withdraw any native coins accidentally deposited to the Public Mint contract.

### withdrawFundsERC20

```solidity
function withdrawFundsERC20(address target, address tokenAddress) public returns (bool)
```

Permissioned function to withdraw any tokens accidentally deposited to the Public Mint contract.

## UPMintPublic

### mintRate

```solidity
uint256 mintRate
```

### UP_TOKEN

```solidity
address UP_TOKEN
```

### UP_CONTROLLER

```solidity
address payable UP_CONTROLLER
```

### NewPublicMintRate

```solidity
event NewPublicMintRate(uint256 _newMintRate)
```

### PublicMint

```solidity
event PublicMint(address _from, uint256 _amount, uint256 _price, uint256 _value)
```

### UpdateController

```solidity
event UpdateController(address _upController)
```

### constructor

```solidity
constructor(address _UP, address payable _UPController, uint256 _mintRate) public
```

### mintUP

```solidity
function mintUP() public payable
```

### setMintRate

```solidity
function setMintRate(uint256 _mintRate) public
```

| Name | Type | Description |
| ---- | ---- | ----------- |
| _mintRate | uint256 | - mint rate in percent texrms, _mintRate &#x3D; 5 &#x3D; 5%. |

### updateController

```solidity
function updateController(address _upController) public
```

### pause

```solidity
function pause() public
```

### unpause

```solidity
function unpause() public
```

### withdrawFunds

```solidity
function withdrawFunds(address target) public returns (bool)
```

### withdrawFundsERC20

```solidity
function withdrawFundsERC20(address target, address tokenAddress) public returns (bool)
```

### fallback

```solidity
fallback() external payable
```

### receive

```solidity
receive() external payable
```

