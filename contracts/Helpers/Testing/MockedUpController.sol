pragma solidity ^0.8.7;

contract MockedUpController {
  uint256 mockedBalance;

  constructor(uint256 _mockedBalance) {
    mockedBalance = _mockedBalance;
  }

  function getNativeBalance() public view returns (uint256) {
    return mockedBalance;
  }

  receive() external payable {}
}
