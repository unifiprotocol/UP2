# Solidity API

## UP

### MINT_ROLE

```solidity
bytes32 MINT_ROLE
```

### onlyMint

```solidity
modifier onlyMint()
```

### constructor

```solidity
constructor() public
```

### burn

```solidity
function burn(uint256 amount) public
```

### burnFrom

```solidity
function burnFrom(address account, uint256 amount) public
```

### justBurn

```solidity
function justBurn(uint256 amount) external
```

Retrocompatible function with v1

### mint

```solidity
function mint(address account, uint256 amount) public
```

## UP

### MINT_ROLE

```solidity
bytes32 MINT_ROLE
```

### LEGACY_MINT_ROLE

```solidity
bytes32 LEGACY_MINT_ROLE
```

### UP_CONTROLLER

```solidity
address UP_CONTROLLER
```

### onlyMint

```solidity
modifier onlyMint()
```

### onlyAdmin

```solidity
modifier onlyAdmin()
```

### constructor

```solidity
constructor() public
```

### burn

```solidity
function burn(uint256 amount) public
```

### burnFrom

```solidity
function burnFrom(address account, uint256 amount) public
```

### justBurn

```solidity
function justBurn(uint256 amount) external
```

Retrocompatible function with v1

### mint

```solidity
function mint(address to, uint256 amount) public payable
```

Mints token and have logic for supporting legacy mint logic

### setController

```solidity
function setController(address newController) public
```

Sets a controller address that will receive the funds from LEGACY_MINT_ROLE

## UP

### MINT_ROLE

```solidity
bytes32 MINT_ROLE
```

### LEGACY_MINT_ROLE

```solidity
bytes32 LEGACY_MINT_ROLE
```

### UP_CONTROLLER

```solidity
address UP_CONTROLLER
```

### onlyMint

```solidity
modifier onlyMint()
```

### onlyAdmin

```solidity
modifier onlyAdmin()
```

### constructor

```solidity
constructor() public
```

### burn

```solidity
function burn(uint256 amount) public
```

### burnFrom

```solidity
function burnFrom(address account, uint256 amount) public
```

### justBurn

```solidity
function justBurn(uint256 amount) external
```

Retrocompatible function with v1

### mint

```solidity
function mint(address to, uint256 amount) public payable
```

Mints token and have logic for supporting legacy mint logic

### setController

```solidity
function setController(address newController) public
```

Sets a controller address that will receive the funds from LEGACY_MINT_ROLE

## UP

### MINT_ROLE

```solidity
bytes32 MINT_ROLE
```

### onlyMint

```solidity
modifier onlyMint()
```

### constructor

```solidity
constructor() public
```

### burn

```solidity
function burn(uint256 amount) public
```

### burnFrom

```solidity
function burnFrom(address account, uint256 amount) public
```

### justBurn

```solidity
function justBurn(uint256 amount) external
```

### mint

```solidity
function mint(address account, uint256 amount) public
```

