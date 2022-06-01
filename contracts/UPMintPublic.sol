// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./UP.sol";
import "./UPController.sol";
import "./Helpers/Safe.sol";

/// @title UP Public Mint
/// @author dxffffff & A Fistful of Stray Cat Hair
/// @notice This contract is for the public minting of UP token, allowing users to deposit native tokens and receive UP tokens.

contract UPMintPublic is Ownable, Pausable, ReentrancyGuard, Safe {
  uint256 public mintRate;
  address payable public UP_TOKEN = payable(address(0));
  address payable public UP_CONTROLLER = payable(address(0));

  event NewPublicMintRate(uint256 _newMintRate);
  event PublicMint(
    address indexed _from,
    address _to,
    uint256 _amount,
    uint256 _price,
    uint256 _value
  );
  event UpdateController(address _upController);

  constructor(
    address _UP,
    address _UPController,
    uint256 _mintRate
  ) {
    require(_UP != address(0), "Invalid UP address");
    UP_TOKEN = payable(_UP);
    UP_CONTROLLER = payable(_UPController);
    setMintRate(_mintRate);
  }

  /// @notice Payable function that mints UP at the mint rate, deposits the native tokens to the UP Controller, Sends UP to the Msg.sender
  /// @param to Destination address for minted tokens
  function mintUP(address to) public payable whenNotPaused nonReentrant {
    require(msg.value > 0, "INVALID_PAYABLE_AMOUNT");
    uint256 currentPrice = UPController(UP_CONTROLLER).getVirtualPrice();
    require(currentPrice > 0, "UP_PRICE_0");
    uint256 discountedAmount = msg.value - ((msg.value * (mintRate * 100)) / 10000);
    uint256 mintAmount = (discountedAmount * currentPrice) / 1e18;
    UP(UP_TOKEN).mint(to, mintAmount);
    (bool successTransfer, ) = address(UP_CONTROLLER).call{value: msg.value}("");
    require(successTransfer, "FAIL_SENDING_NATIVE");
    emit PublicMint(msg.sender, to, mintAmount, currentPrice, msg.value);
  }

  /// @notice Permissioned function that sets the public rint of UP.
  /// @param _mintRate - mint rate in percent terms, _mintRate = 5 = 5%.
  function setMintRate(uint256 _mintRate) public onlyOwner {
    require(_mintRate <= 100, "MINT_RATE_GT_100");
    require(_mintRate > 0, "MINT_RATE_EQ_0");
    mintRate = _mintRate;
    emit NewPublicMintRate(_mintRate);
  }

  /// @notice Permissioned function to update the address of the UP Controller
  /// @param _upController - the address of the new UP Controller
  function updateController(address _upController) public onlyOwner {
    require(_upController != address(0), "INVALID_ADDRESS");
    UP_CONTROLLER = payable(_upController);
    emit UpdateController(_upController);
  }

  /// @notice Permissioned function to pause public minting
  function pause() public onlyOwner {
    _pause();
  }

  /// @notice Permissioned function to unpause public minting
  function unpause() public onlyOwner {
    _unpause();
  }

  /// @notice Permissioned function to withdraw any native coins accidentally deposited to the Public Mint contract.
  function withdrawFunds(address target) public onlyOwner returns (bool) {
    return _withdrawFunds(target);
  }

  /// @notice Permissioned function to withdraw any tokens accidentally deposited to the Public Mint contract.
  function withdrawFundsERC20(address target, address tokenAddress)
    public
    onlyOwner
    returns (bool)
  {
    return _withdrawFundsERC20(target, tokenAddress);
  }
}
