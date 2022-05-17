# UPv2

This repository contains the smart contracts for the new version of the UP contract:

- ERC20 Token
- Token public minting
- Token controller for pricing and internal handling

## Contracts

- `UP.sol` ERC20 implementation of the UP token.
- `UPMintPublic.sol` This contract is public and have the logic for minting UP with a Premium price using native token: `ETH amount * %Premium`.
- `UPController.sol` Because the value of UP is made by the reserves of native token, this contract will store all the native reserves and will control de price of the token. Also, contains logic for borrowing and minting UP token under the arbitrage/balancing system.
- `Vendor.sol` Swap contract between UPv1 and UPv2.

## Scripts

```sh
yarn compile # generates typechain types

yarn test # runs test files
```

## Credits

This project is licensed under the [MIT license](LICENSE) and made by the Unifi Protocol Tech team.
