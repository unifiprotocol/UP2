//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../Helpers/Safe.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

enum Directive {
  CREATE_VALIDATOR, // unused
  EDIT_VALIDATOR, // unused
  DELEGATE,
  UNDELEGATE,
  COLLECT_REWARDS
}

abstract contract StakingPrecompilesSelectors {
  function Delegate(
    address delegatorAddress,
    address validatorAddress,
    uint256 amount
  ) public virtual;

  function Undelegate(
    address delegatorAddress,
    address validatorAddress,
    uint256 amount
  ) public virtual;

  function CollectRewards(address delegatorAddress) public virtual;

  function Migrate(address from, address to) public virtual;
}

interface IStakingPrecompiles {
  function delegate(address validatorAddress) external payable returns (uint256 result);

  function undelegate(address validatorAddress, uint256 amount) external returns (uint256 result);

  function collectRewards() external returns (uint256 result);

  function epoch() external view returns (uint256);

  function withdrawUndelegatedFunds() external returns (uint256);
}

contract StakingPrecompiles is IStakingPrecompiles, AccessControl, Safe {
  modifier onlyStrategy() {
    require(hasRole(STRATEGY_ROLE, msg.sender), "StakingPrecompiles: ONLY_STRATEGY");
    _;
  }

  modifier onlyOwner() {
    require(hasRole(OWNER_ROLE, msg.sender), "StakingPrecompiles: ONLY_STRATEGY");
    _;
  }

  modifier onlyStrategyOrOwner() {
    require(
      hasRole(STRATEGY_ROLE, msg.sender) || hasRole(OWNER_ROLE, msg.sender),
      "StakingPrecompiles: ONLY_STRATEGY_OR_ADMIN"
    );
    _;
  }

  bytes32 public constant OWNER_ROLE = keccak256("ADMIN_ROLE");
  bytes32 public constant STRATEGY_ROLE = keccak256("STRATEGY_ROLE");

  constructor(address safeFundsTarget, address stakingStrategy) Safe(safeFundsTarget) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(OWNER_ROLE, msg.sender);
    _setupRole(STRATEGY_ROLE, stakingStrategy);
    strategy = stakingStrategy;
  }

  address strategy;

  function delegate(address validatorAddress)
    public
    payable
    virtual
    override
    onlyStrategy
    returns (uint256 result)
  {
    bytes memory encodedInput = abi.encodeWithSelector(
      StakingPrecompilesSelectors.Delegate.selector,
      address(this),
      validatorAddress,
      msg.value
    );
    assembly {
      // we estimate a gas consumption of 25k per precompile
      result := call(
        25000,
        0xfc,
        0x0,
        add(encodedInput, 32),
        mload(encodedInput),
        mload(0x40),
        0x20
      )
    }
  }

  function undelegate(address validatorAddress, uint256 amount)
    public
    virtual
    override
    onlyStrategyOrOwner
    returns (uint256 result)
  {
    bytes memory encodedInput = abi.encodeWithSelector(
      StakingPrecompilesSelectors.Undelegate.selector,
      address(this),
      validatorAddress,
      amount
    );
    assembly {
      // we estimate a gas consumption of 25k per precompile
      result := call(
        25000,
        0xfc,
        0x0,
        add(encodedInput, 32),
        mload(encodedInput),
        mload(0x40),
        0x20
      )
    }
  }

  function collectRewards() public virtual override onlyStrategyOrOwner returns (uint256 result) {
    bytes memory encodedInput = abi.encodeWithSelector(
      StakingPrecompilesSelectors.CollectRewards.selector,
      address(this)
    );
    assembly {
      // we estimate a gas consumption of 25k per precompile
      result := call(
        25000,
        0xfc,
        0x0,
        add(encodedInput, 32),
        mload(encodedInput),
        mload(0x40),
        0x20
      )
    }
    (bool success, ) = msg.sender.call{value: result}("");
    require(success, "StakingPrecompiles: FAIL_SENDING_NATIVE");
  }

  function epoch() public view override returns (uint256) {
    bytes32 input;
    bytes32 epochNumber;
    assembly {
      let memPtr := mload(0x40)
      if iszero(staticcall(not(0), 0xfb, input, 32, memPtr, 32)) {
        invalid()
      }
      epochNumber := mload(memPtr)
    }
    return uint256(epochNumber);
  }

  function withdrawUndelegatedFunds() external override onlyStrategy returns (uint256) {
    uint256 amount = address(this).balance;
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "StakingPrecompiles: FAIL_SENDING_NATIVE");
    return amount;
  }
}
