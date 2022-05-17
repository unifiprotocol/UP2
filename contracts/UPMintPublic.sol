// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./UP.sol";
import "./UPController.sol";
import "./Helpers/Safe.sol";
import "hardhat/console.sol";

contract UPMintPublic is Ownable, Pausable, Safe {
    uint256 public mintRate = 95000;
    address public UP_TOKEN = address(0);
    address public UP_CONTROLLER = address(0);
    address payable UP_CONTROLLERPAYABLE = payable(UP_CONTROLLER);


    event NewPublicMintRate(uint256 _newMintRate);
    event PublicMint(address indexed _from, uint256 _amount, uint256 _price, uint256 _value);
    event UpdateController(address _upController);


  constructor(address _UP, address payable _UPController, uint256 _mintRate) {
    require(_UP != address(0), "Invalid UP address");
    UP_TOKEN = _UP;
    UP_CONTROLLER = _UPController;
    setMintRate(_mintRate);
  }

  
  function getVirtualMintPrice(uint256 _depositedAmount) public view returns (uint256) {
    if (UPController(UP_CONTROLLERPAYABLE).getNativeBalance() - _depositedAmount == 0) return 0;
    uint256 upTotalSupply = UP(UP_TOKEN).totalSupply();
    uint256 upBorrowed = UPController(UP_CONTROLLERPAYABLE).upBorrowed();
    return ((UPController(UP_CONTROLLERPAYABLE).getNativeBalance() - _depositedAmount) * 1e18) /
      (upTotalSupply - upBorrowed);
  }

    function mintUP() public payable whenNotPaused {
    require(msg.value > 0, "INVALID_PAYABLE_AMOUNT");
    uint256 currentPrice = getVirtualMintPrice(msg.value);
    if (currentPrice == 0) return;
    uint256 discountedAmount = msg.value - ((msg.value * (mintRate * 100)) / 10000);
    uint256 mintAmount = (discountedAmount * currentPrice) / 1e18;
    UP(UP_TOKEN).mint(msg.sender, mintAmount);
    emit PublicMint(msg.sender, mintAmount, currentPrice, msg.value);
  }

  /**
   * @param _mintRate - mint rate in percent texrms, _mintRate = 5 = 5%.
   */
  function setMintRate(uint256 _mintRate) public onlyOwner {
    require(_mintRate <= 100, "MINT_RATE_GT_100");
    mintRate = _mintRate;
    emit NewPublicMintRate(_mintRate);
  }

  function updateController(address _upController) public onlyOwner {
    require(_upController != address(0), 'INVALID_ADDRESS');
    UP_CONTROLLER = _upController;
    emit UpdateController(_upController);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

    function withdrawFunds(address target) public onlyOwner returns (bool) {
    return _withdrawFunds(target);
  }

  function withdrawFundsERC20(address target, address tokenAddress)
    public
    onlyOwner
    returns (bool)
  {
    return _withdrawFundsERC20(target, tokenAddress);
  }

  
  fallback() external payable {}

  receive() external payable {}
}
