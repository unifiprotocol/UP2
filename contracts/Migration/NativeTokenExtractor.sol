//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IUP {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function getVirtualPrice() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function mint(address to, uint256 value) external payable returns (bool);

  function burn(uint256 value) external;

  function transferOwnership(address account) external;

  function updateValues(string calldata fieldName, uint256 amount) external;

  function justBurn(uint256 value) external;

  function addMinter(address account) external;
}

contract Migrator {
  //main account UP owner to  approve this contract to mintUP/minter
  //main account set mintRate to Unlimited 0

  address public owner;

  constructor() {
    owner = msg.sender;
  }

  function withdrawBalance(address _to) external {
    require(owner == msg.sender, "Unauthorized");
    payable(address(_to)).transfer(address(this).balance);
  }

  //for legacy UP minting call back hook
  function updateFeeState(uint256 _fee) external returns (bool) {
    require(owner == msg.sender, "Unauthorized");
    return true;
  }

  function transferUPOwnership(address _newaddress, address _Uptoken) external {
    IUP(_Uptoken).transferOwnership(_newaddress);
  }

  // mint rate should be set to 0 first
  //https://testnet.bscscan.com/tx/0x2e4a1c8a455915caa7b651961d5c4d07a0b9ac97e5d4c12fb1a3f0d08cabbce9
  function extractNative(
    address _Uptoken,
    uint256 multiplier,
    bool forceCheck
  ) external payable {
    require(owner == msg.sender, "Unauthorized");
    uint256 totalSupply = IUP(_Uptoken).totalSupply();
    //IUP(_Uptoken).addMinter(address(this));
    IUP(_Uptoken).updateValues("MintRate", totalSupply * multiplier);
    IUP(_Uptoken).mint{value: msg.value}(address(this), msg.value);
    uint256 nativeBalance = address(_Uptoken).balance;
    uint256 redeemPrice = IUP(_Uptoken).getVirtualPrice();
    uint256 noOfUpToBurn = (nativeBalance * 1e18) / redeemPrice;
    if (forceCheck) {
      require(
        noOfUpToBurn <= IUP(_Uptoken).balanceOf(address(this)),
        " not enough UP token minted  to "
      );
    }

    IUP(_Uptoken).burn(noOfUpToBurn);
    IUP(_Uptoken).justBurn(IUP(_Uptoken).balanceOf(address(this)));
    IUP(_Uptoken).updateValues("MintRate", 0);
  }

  function mintUP(address upToken) external payable {
    require(owner == msg.sender, "Unauthorized");
    IUP(upToken).mint{value: msg.value}(address(this), msg.value);
  }

  function manualBurnUp(address upToken, uint256 amount) external {
    IUP(upToken).burn(amount);
  }
}
