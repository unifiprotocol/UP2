// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @custom:security-contact adam@unifiprotocol.com
contract UPv2New is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, ERC20SnapshotUpgradeable, AccessControlUpgradeable, PausableUpgradeable, ERC20PermitUpgradeable, UUPSUpgradeable {
    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __ERC20_init("UPv2New", "UPv2New");
        __ERC20Burnable_init();
        __ERC20Snapshot_init();
        __AccessControl_init();
        __Pausable_init();
        __ERC20Permit_init("UPv2New");
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); //Will be Multi-sig Quorum over 80%
        _grantRole(SNAPSHOT_ROLE, msg.sender); //Will be Multi-sig Quorum over 80%
        _grantRole(PAUSER_ROLE, msg.sender); //Will be Multi-sig Quorum over 80%
        _grantRole(MINTER_ROLE, msg.sender); //Will be UP Controller
        _grantRole(UPGRADER_ROLE, msg.sender); //Will be Multi-sig Quorum over 80%
    }
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _mintRate = 95000;
    uint256 private totalUPBurnt = 0;
    uint256 private totalFeesGiven = 0;
    mapping (address => uint256) private _balances;  
    mapping (address => mapping (address => uint256)) private _allowed;
    uint256 private _totalSupply;
    address public controllerAddress;
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


    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override(ERC20Upgradeable, ERC20SnapshotUpgradeable)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    function snapshot() public onlyRole(SNAPSHOT_ROLE) {
        _snapshot();
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public payable returns (bool) {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
       require(msg.value == amount, "Invalid native token");
        uint256 Value = getVirtualPriceForMinting(amount);
        uint256 MintAmount = amount*(_mintRate)*(1e18)/(Value*(100000));  
        _mint(to, MintAmount);
        return true;
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

}