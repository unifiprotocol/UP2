pragma solidity ^0.8.7;

contract MockedRebalancer {
  uint256 allocationRedeem;
  uint256 allocationLP;

  constructor(uint256 _allocationRedeem, uint256 _allocationLP) {
    allocationRedeem = _allocationRedeem;
    allocationLP = _allocationLP;
  }

  function setAllocationRedeem(uint256 _allocationRedeem) public {
    allocationRedeem = _allocationRedeem;
  }

  function setAllocationLP(uint256 _allocationLP) public {
    allocationLP = _allocationLP;
  }
}
