// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @custom:security-contact adam@unifiprotocol.com
contract UPbnb is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant DARBI_ROLE = keccak256("DARBI_ROLE");
    bytes32 public constant STAKING_ROLE = keccak256("STAKING_ROLE");

    constructor() ERC20("UPbnb", "UPbnb") {
        _grantRole(ADMIN_ROLE, msg.sender); // Multi Sig
        _grantRole(MINTER_ROLE, msg.sender); // 5% Mint Rate
        _grantRole(DARBI_ROLE, msg.sender); // 0% Mint Rate
        _grantRole(STAKING_ROLE, msg.sender);
    }

 
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _mintRate = 95000;
    uint256 private _publicMintRate = 95000;
    uint256 private _darbiMintRate = 100000;
    uint256 private totalUPBurnt = 0;
    uint256 private totalFeesGiven = 0;
    mapping (address => uint256) private _balances;  
    mapping (address => mapping (address => uint256)) private _allowed;
    uint256 private _totalSupply;
    address public controllerAddress;
    address public darbiAddress;
    uint public nativedBorrowed = 0;
    uint public upBorrowed = 0 ;
    
    event JustDeposit(
        address indexed owner,
        uint256 value
    );
    event UpdateMintRate(uint _amount);
    event BorrowNative(uint _amount);
    event BorrowUP(uint _amount);
    event UpdateControllerAddress(address _newController);
    event ClearNativeDebt(uint amount);
    event ClearUPDebt(uint amount);

// Read Functions
  function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply - upBorrowed;
    }

    function getVirtualPrice() public view returns(uint256){
        uint256 baseTokenbal = getNativeTotal();
        uint256 Value =(baseTokenbal*(1e18))/(_totalSupply-upBorrowed); 
        return Value;
    }

  /**
     * @return the number UP redeem price
     */
    function getRedeemValue() public view returns(uint256){
        uint256 baseTokenbal = getNativeTotal();
        uint256 Value =(baseTokenbal*(1e18))/(_totalSupply-upBorrowed); 
        return Value;
    }

    function getVirtualPriceForMinting(uint value) public view returns(uint256){
        uint256 baseTokenbal = getNativeTotal() - value;
        uint256 Value =(baseTokenbal*(1e18))/(_totalSupply- upBorrowed); 
        return Value;
    }

    /**
     * @return the total number of native token backing UP
     */
    function getNativeTotal() public view returns(uint){
        return (address(this).balance + nativedBorrowed);
    }
 // Write Functions
    // Legacy Mint for uTrade and any other 5% 
   function mint(address to, uint256 amount) public payable onlyRole(MINTER_ROLE) {
        require(msg.value == amount, "Invalid native token");
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        uint256 Value = getVirtualPriceForMinting(amount);
        uint256 MintAmount = amount*(_mintRate)*(1e18)/(Value*(100000));  //Unused Variable?
        _mint(to, amount);
    }

    function publicMint(address to, uint256 amount) public payable {
        require(msg.value == amount, "Invalid native token");
        uint256 Value = getVirtualPriceForMinting(amount);
        uint256 MintAmount = amount*(_publicMintRate)*(1e18)/(Value*(100000));  //Unused Variable?
        _mint(to, amount);
    }

    function darbiMint(address to, uint256 amount) public payable onlyRole(DARBI_ROLE) {
        require(msg.value == amount, "Invalid native token");
        require(hasRole(DARBI_ROLE, msg.sender), "Caller is not a minter");
        uint256 Value = getVirtualPriceForMinting(amount);
        uint256 MintAmount = amount*(_darbiMintRate)*(1e18)/(Value*(100000));  //Unused Variable?
        _mint(to, amount);
    }

    function _mint(address account, uint256 value) internal override {
        require(account != address(0));
        _totalSupply = _totalSupply + (value);
        _balances[account] = _balances[account] + (value);
        emit Transfer(address(0), account, value);
    }

    function updateControllerAddress(address  _newController) public onlyRole(ADMIN_ROLE) {
        controllerAddress = _newController;
        emit UpdateControllerAddress( _newController) ;    
    }   
}