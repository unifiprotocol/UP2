// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./UPMintPublic.sol";

/// @title UPWhitelistedMint
/// @author dxffffff & A Fistful of Stray Cat Hair & Kerk
/// @notice This contract allows to mint UP for a bunch of whitelisted addresses.

contract UPWhitelistedMint is UPMintPublic {
  mapping(address => bool) public whiteListedAddress;
  event WhiteListAdded(address _account);
  event WhiteListRemoved(address _account);

  constructor(
    address _UP,
    address _UPController,
    uint256 _mintRate,
    address _fundsTarget
  ) UPMintPublic(_UP, _UPController, _mintRate, _fundsTarget) {}

  modifier onlyWhitelisted() {
    require(whiteListedAddress[msg.sender] == true, "UPWhitelistedMint: ONLY_WHITELISTED");
    _;
  }

  /// @notice Payable function that mints UP at the mint rate, deposits the native tokens to the UP Controller, Sends UP to the Msg.sender
  /// @param to Destination address for minted tokens
  function mintUP(address to) public payable override onlyWhitelisted {
    super.mintUP(to);
  }

  function addWhiteListed(address[] memory account) public onlyOwner {
    uint256 i = 0;
    while (i < account.length) {
      whiteListedAddress[account[i]] = true;
      emit WhiteListAdded(account[i]);
      i++;
    }
  }

  function removeWhiteListed(address[] memory account) public onlyOwner {
    uint256 i = 0;
    while (i < account.length) {
      whiteListedAddress[account[i]] = false;
      emit WhiteListRemoved(account[i]);
      i++;
    }
  }

  function preLoadData() internal {
    //sample data
    whiteListedAddress[0x4Fa62Ce3Faac2327F0F795256aB87BD9DFC2660A] = true;
  }
}
