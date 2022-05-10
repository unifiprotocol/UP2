// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @custom:security-contact adam@unifiprotocol.com
contract UPbnb is ERC20, ERC20Burnable, AccessControl {
    //Beginning to think we can just have one admin role, which is arguably simplier. Will revisit.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
   

    constructor() ERC20("UPbnb", "UPbnb") {
        _grantRole(ADMIN_ROLE, msg.sender); // Multi Sig
        _grantRole(MINTER_ROLE, msg.sender);
        _mint(msg.sender, 1000000000000000000);
    }

 // Variables 
    // string private _name;
    // string private _symbol;
    // uint8 private _decimals;
    uint256 private _mintRate = 95000;
    uint256 private _publicMintRate = 95000;
    uint256 private _darbiMintRate = 100000;
    uint256 private _rebalancerRate = 95000;
    uint256 private totalUPBurnt = 0;
    uint256 private totalFeesGiven = 0;
    mapping (address => uint256) private _balances;  
    // mapping (address => mapping (address => uint256)) private _allowed;
    uint256 private _totalSupply;  
    uint public nativeBorrowed = 0;
    uint public upBorrowed = 0 ;
    address public rebalancerAddress = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address public darbiAddress = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address public controllerAddress;

// Events

    event JustDeposit(
        address indexed owner,
        uint256 value
    );
    event UpdateMintRate(uint _amount);
    event BorrowNative(uint _borrowNativeAmount);
    event BorrowUP(uint _borrowUPAmount);
    event RepayNative(uint _repayNativeAmount);
    event UpdateControllerAddress(address _newController);
    event UpdateDarbiAddress(address _newDarbi);
    event UpdateRebalancerAddress(address _newRebalancer);

// Modifiers


    modifier onlyController() {
        require(msg.sender == controllerAddress , "Unifi : Only Controller");
         _;
    }

    modifier onlyDarbi() {
        require(msg.sender == darbiAddress , "Unifi : Only Darbi");
         _;
    }

    modifier onlyRebalancer() {
        require(msg.sender == rebalancerAddress , "Unifi : Only Rebalancer");
         _;
    }

// Read Functions

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply - upBorrowed;
    }

    function balanceOf(address holder) public view virtual override returns (uint256) {
        return _balances[holder];
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
        return (address(this).balance + nativeBorrowed);
    }

 // Write Functions
    // Legacy Mint for uTrade
   function mint(address to, uint256 amount) public payable {
        require(msg.value == amount, "Invalid native token");
        require(msg.sender == controllerAddress, "Caller is not a minter");
        uint256 Value = getVirtualPriceForMinting(amount);
        uint256 MintAmount = amount*(_mintRate)*(1e18)/(Value*(100000));
        _mint(to, MintAmount);
    }
    // Rebalancer Mint Function
    function rebalancerMint(address to, uint256 amount) public payable onlyRebalancer {
        require(msg.value == amount, "Invalid native token");
        uint256 Value = getVirtualPriceForMinting(amount);
        uint256 MintAmount = amount*(_rebalancerRate)*(1e18)/(Value*(100000));
        _mint(to, MintAmount);
    }

    // Darby Mint Function
    function darbiMint(address to, uint256 amount) public payable onlyDarbi {
        require(msg.value == amount, "Invalid native token");
        uint256 Value = getVirtualPriceForMinting(amount);
        uint256 MintAmount = amount*(_darbiMintRate)*(1e18)/(Value*(100000)); 
        _mint(to, MintAmount);
    }

    // Public Mint Function
    function publicMint(address to, uint256 amount) public payable {
        require(msg.value == amount, "Invalid native token");
        uint256 Value = getVirtualPriceForMinting(amount);
        uint256 MintAmount = amount*(_publicMintRate)*(1e18)/(Value*(100000));
        _mint(to, MintAmount);
    }

    // Synthetic Mint Function
    function borrowUP(uint _borrowUPAmount) public onlyRebalancer {
        upBorrowed += _borrowUPAmount ;
        _mint(rebalancerAddress, _borrowUPAmount);
         emit BorrowUP(_borrowUPAmount);       
    }
    
    // Internal Mint Function
    function _mint(address account, uint256 value) internal override {
        require(account != address(0));
        _totalSupply = _totalSupply + (value);
        _balances[account] = _balances[account] + (value);
        emit Transfer(address(0), account, value);
    }

    // Borrow Native Tokens

    function borrowNative(uint _borrowNativeAmount) public onlyRebalancer {
        nativeBorrowed += _borrowNativeAmount;
        payable(address(rebalancerAddress)).transfer(_borrowNativeAmount);
        emit BorrowNative(_borrowNativeAmount);       
    }

    // Repay Native Tokens

    function repayNative(uint _repayNativeAmount) public payable onlyRebalancer {
        require(_repayNativeAmount <= nativeBorrowed, "Transaction is repaying more than is owed");
        require(msg.value == _repayNativeAmount, "Repay Native Amount parameter differs from Payable amount");
        nativeBorrowed -= _repayNativeAmount;
        emit RepayNative(_repayNativeAmount);       
    }



    // 
    function justDeposit(uint256 value) public payable {
        _justDeposit(msg.sender, value);

    }

    function _justDeposit(address depositor, uint256 value) internal {
        emit JustDeposit(depositor,value);
    }

    //Admin Functions

    function updateControllerAddress(address  _newController) public onlyRole(ADMIN_ROLE) {
        controllerAddress = _newController;
        emit UpdateControllerAddress( _newController) ;    
    }

    function updateDarbiAddress(address  _newDarbi) public onlyRole(ADMIN_ROLE) {
        darbiAddress = _newDarbi;
        emit UpdateDarbiAddress( _newDarbi);    
    }

    function updateRebalancerAddress(address  _newRebalancer) public onlyRole(ADMIN_ROLE) {
        rebalancerAddress = _newRebalancer;
        emit UpdateRebalancerAddress(_newRebalancer);    
    }  

    // Fallback Functions

    fallback() external payable {
        if(msg.value > 0 ){
            _justDeposit(msg.sender,msg.value);
        }
    }

    receive() external payable {
        if(msg.value > 0 ){
            _justDeposit(msg.sender,msg.value);
        }
    }

}