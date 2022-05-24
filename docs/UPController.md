# Solidity API

## UPController

This controller back up the UP token and has the logic for borrowing tokens.

### REBALANCER_ROLE

```solidity
bytes32 REBALANCER_ROLE
```

### REDEEMER_ROLE

```solidity
bytes32 REDEEMER_ROLE
```

### UP_TOKEN

```solidity
address UP_TOKEN
```

### nativeBorrowed

```solidity
uint256 nativeBorrowed
```

### upBorrowed

```solidity
uint256 upBorrowed
```

### SyntheticMint

```solidity
event SyntheticMint(address _from, uint256 _amount, uint256 _newUpBorrowed)
```

### BorrowNative

```solidity
event BorrowNative(address _from, uint256 _amount, uint256 _newNativeBorrowed)
```

### Repay

```solidity
event Repay(uint256 _nativeAmount, uint256 _upAmount)
```

### Redeem

```solidity
event Redeem(uint256 _upAmount, uint256 _redeemAmount)
```

### onlyRebalancer

```solidity
modifier onlyRebalancer()
```

### onlyAdmin

```solidity
modifier onlyAdmin()
```

### onlyRedeemer

```solidity
modifier onlyRedeemer()
```

### constructor

```solidity
constructor(address _UP) public
```

### receive

```solidity
receive() external payable
```

### getVirtualPrice

```solidity
function getVirtualPrice() public view returns (uint256)
```

Returns price of UP token based on its reserves

### getNativeBalance

```solidity
function getNativeBalance() public view returns (uint256)
```

Computed the actual native balances of the contract

### actualTotalSupply

```solidity
function actualTotalSupply() public view returns (uint256)
```

Computed total supply of UP token

### borrowNative

```solidity
function borrowNative(uint256 _borrowAmount, address _to) public
```

Borrows native token from the back up reserves

### borrowUP

```solidity
function borrowUP(uint256 _borrowAmount, address _to) public
```

Borrows UP token minting it

### mintSyntheticUP

```solidity
function mintSyntheticUP(uint256 _mintAmount, address _to) public
```

### repay

```solidity
function repay(uint256 upAmount) public payable
```

Allows to return back borrowed amounts to the controller

### redeem

```solidity
function redeem(uint256 upAmount) public
```

Swaps UP token by native token

### withdrawFunds

```solidity
function withdrawFunds(address target) public returns (bool)
```

### withdrawFundsERC20

```solidity
function withdrawFundsERC20(address target, address tokenAddress) public returns (bool)
```

## UPController

This controller back up the UP token and has the logic for borrowing tokens.

### REBALANCER_ROLE

```solidity
bytes32 REBALANCER_ROLE
```

### REDEEMER_ROLE

```solidity
bytes32 REDEEMER_ROLE
```

### UP_TOKEN

```solidity
address UP_TOKEN
```

### nativeBorrowed

```solidity
uint256 nativeBorrowed
```

### upBorrowed

```solidity
uint256 upBorrowed
```

### SyntheticMint

```solidity
event SyntheticMint(address _from, uint256 _amount, uint256 _newUpBorrowed)
```

### BorrowNative

```solidity
event BorrowNative(address _from, uint256 _amount, uint256 _newNativeBorrowed)
```

### Repay

```solidity
event Repay(uint256 _nativeAmount, uint256 _upAmount)
```

### Redeem

```solidity
event Redeem(uint256 _upAmount, uint256 _redeemAmount)
```

### onlyRebalancer

```solidity
modifier onlyRebalancer()
```

### onlyAdmin

```solidity
modifier onlyAdmin()
```

### onlyRedeemer

```solidity
modifier onlyRedeemer()
```

### constructor

```solidity
constructor(address _UP) public
```

### receive

```solidity
receive() external payable
```

### getVirtualPrice

```solidity
function getVirtualPrice() public view returns (uint256)
```

Returns price of UP token based on its reserves

### getVirtualPrice

```solidity
function getVirtualPrice(uint256 sentValue) public view returns (uint256)
```

Returns price of UP token based on its reserves minus amount sent to the contract

### getNativeBalance

```solidity
function getNativeBalance() public view returns (uint256)
```

Computed the actual native balances of the contract

### actualTotalSupply

```solidity
function actualTotalSupply() public view returns (uint256)
```

Computed total supply of UP token

### borrowNative

```solidity
function borrowNative(uint256 _borrowAmount, address _to) public
```

Borrows native token from the back up reserves

### borrowUP

```solidity
function borrowUP(uint256 _borrowAmount, address _to) public
```

Borrows UP token minting it

### mintSyntheticUP

```solidity
function mintSyntheticUP(uint256 _mintAmount, address _to) public
```

### mintUP

```solidity
function mintUP(address to) external payable
```

Mints UP based on virtual price - UPv1 logic

### repay

```solidity
function repay(uint256 upAmount) public payable
```

Allows to return back borrowed amounts to the controller

### redeem

```solidity
function redeem(uint256 upAmount) public
```

Swaps UP token by native token

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

## UPController

This controller back up the UP token and has the logic for borrowing tokens.

### REBALANCER_ROLE

```solidity
bytes32 REBALANCER_ROLE
```

### REDEEMER_ROLE

```solidity
bytes32 REDEEMER_ROLE
```

### UP_TOKEN

```solidity
address UP_TOKEN
```

### nativeBorrowed

```solidity
uint256 nativeBorrowed
```

### upBorrowed

```solidity
uint256 upBorrowed
```

### SyntheticMint

```solidity
event SyntheticMint(address _from, uint256 _amount, uint256 _newUpBorrowed)
```

### BorrowNative

```solidity
event BorrowNative(address _from, uint256 _amount, uint256 _newNativeBorrowed)
```

### Repay

```solidity
event Repay(uint256 _nativeAmount, uint256 _upAmount)
```

### Redeem

```solidity
event Redeem(uint256 _upAmount, uint256 _redeemAmount)
```

### onlyRebalancer

```solidity
modifier onlyRebalancer()
```

### onlyAdmin

```solidity
modifier onlyAdmin()
```

### onlyRedeemer

```solidity
modifier onlyRedeemer()
```

### constructor

```solidity
constructor(address _UP) public
```

### receive

```solidity
receive() external payable
```

### getVirtualPrice

```solidity
function getVirtualPrice() public view returns (uint256)
```

Returns price of UP token based on its reserves

### getVirtualPrice

```solidity
function getVirtualPrice(uint256 sentValue) public view returns (uint256)
```

Returns price of UP token based on its reserves minus amount sent to the contract

### getNativeBalance

```solidity
function getNativeBalance() public view returns (uint256)
```

Computed the actual native balances of the contract

### actualTotalSupply

```solidity
function actualTotalSupply() public view returns (uint256)
```

Computed total supply of UP token

### borrowNative

```solidity
function borrowNative(uint256 _borrowAmount, address _to) public
```

Borrows native token from the back up reserves

### borrowUP

```solidity
function borrowUP(uint256 _borrowAmount, address _to) public
```

Borrows UP token minting it

### mintSyntheticUP

```solidity
function mintSyntheticUP(uint256 _mintAmount, address _to) public
```

### mintUP

```solidity
function mintUP(address to) external payable
```

Mints UP based on virtual price - UPv1 logic

### repay

```solidity
function repay(uint256 upAmount) public payable
```

Allows to return back borrowed amounts to the controller

### redeem

```solidity
function redeem(uint256 upAmount) public
```

Swaps UP token by native token

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

## UPController

This controller back up the UP token and has the logic for borrowing tokens.

### REBALANCER_ROLE

```solidity
bytes32 REBALANCER_ROLE
```

### REDEEMER_ROLE

```solidity
bytes32 REDEEMER_ROLE
```

### UP_TOKEN

```solidity
address UP_TOKEN
```

### nativeBorrowed

```solidity
uint256 nativeBorrowed
```

### upBorrowed

```solidity
uint256 upBorrowed
```

### SyntheticMint

```solidity
event SyntheticMint(address _from, uint256 _amount, uint256 _newUpBorrowed)
```

### BorrowNative

```solidity
event BorrowNative(address _from, uint256 _amount, uint256 _newNativeBorrowed)
```

### Repay

```solidity
event Repay(uint256 _nativeAmount, uint256 _upAmount)
```

### Redeem

```solidity
event Redeem(uint256 _upAmount, uint256 _redeemAmount)
```

### onlyRebalancer

```solidity
modifier onlyRebalancer()
```

### onlyAdmin

```solidity
modifier onlyAdmin()
```

### onlyRedeemer

```solidity
modifier onlyRedeemer()
```

### constructor

```solidity
constructor(address _UP) public
```

### receive

```solidity
receive() external payable
```

### getVirtualPrice

```solidity
function getVirtualPrice() public view returns (uint256)
```

Returns price of UP token based on its reserves

### getVirtualPrice

```solidity
function getVirtualPrice(uint256 sentValue) public view returns (uint256)
```

Returns price of UP token based on its reserves minus amount sent to the contract

### getNativeBalance

```solidity
function getNativeBalance() public view returns (uint256)
```

Computed the actual native balances of the contract

### actualTotalSupply

```solidity
function actualTotalSupply() public view returns (uint256)
```

Computed total supply of UP token

### borrowNative

```solidity
function borrowNative(uint256 _borrowAmount, address _to) public
```

Borrows native token from the back up reserves

### borrowUP

```solidity
function borrowUP(uint256 _borrowAmount, address _to) public
```

Borrows UP token minting it

### mintSyntheticUP

```solidity
function mintSyntheticUP(uint256 _mintAmount, address _to) public
```

### mintUP

```solidity
function mintUP(address to) external payable
```

Mints UP based on virtual price - UPv1 logic

### repay

```solidity
function repay(uint256 upAmount) public payable
```

Allows to return back borrowed amounts to the controller

### redeem

```solidity
function redeem(uint256 upAmount) public
```

Swaps UP token by native token

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

## UPController

### REBALANCER_ROLE

```solidity
bytes32 REBALANCER_ROLE
```

### REDEEMER_ROLE

```solidity
bytes32 REDEEMER_ROLE
```

### UP_TOKEN

```solidity
address UP_TOKEN
```

### nativeBorrowed

```solidity
uint256 nativeBorrowed
```

### upBorrowed

```solidity
uint256 upBorrowed
```

### SyntheticMint

```solidity
event SyntheticMint(address _from, uint256 _amount, uint256 _newUpBorrowed)
```

### BorrowNative

```solidity
event BorrowNative(address _from, uint256 _amount, uint256 _newNativeBorrowed)
```

### Repay

```solidity
event Repay(uint256 _nativeAmount, uint256 _upAmount)
```

### Redeem

```solidity
event Redeem(uint256 _upAmount, uint256 _redeemAmount)
```

### onlyRebalancer

```solidity
modifier onlyRebalancer()
```

### onlyAdmin

```solidity
modifier onlyAdmin()
```

### onlyRedeemer

```solidity
modifier onlyRedeemer()
```

### constructor

```solidity
constructor(address _UP) public
```

### fallback

```solidity
fallback() external payable
```

### receive

```solidity
receive() external payable
```

### getVirtualPrice

```solidity
function getVirtualPrice() public view returns (uint256)
```

### getNativeBalance

```solidity
function getNativeBalance() public view returns (uint256)
```

### actualTotalSupply

```solidity
function actualTotalSupply() public view returns (uint256)
```

### borrowNative

```solidity
function borrowNative(uint256 _borrowAmount, address _to) public
```

### borrowUP

```solidity
function borrowUP(uint256 _borrowAmount, address _to) public
```

### mintSyntheticUP

```solidity
function mintSyntheticUP(uint256 _mintAmount, address _to) public
```

### repay

```solidity
function repay(uint256 upAmount) public payable
```

### redeem

```solidity
function redeem(uint256 upAmount) public
```

### withdrawFunds

```solidity
function withdrawFunds(address target) public returns (bool)
```

### withdrawFundsERC20

```solidity
function withdrawFundsERC20(address target, address tokenAddress) public returns (bool)
```

