// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Strategy.sol";
import "./Interfaces/IVault.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Contract Strategy must use our customized Safe.sol and OpenZeppelin's AccessControl and Pauseable Contracts.
// Safe.sol is utilized so the DAO can retrieve any lost assets within the Strategy Contract.
// AccessControl.sol is utilized so only the Rebalancer can interact with the strategy, and only the DAO can update the Rebalancer Contract.
// Pausable.sol is utilized so that DAO can pause the strategy in an emergency.

contract AlpacaBNBStrategy is Strategy {
  ///@notice The amountDeposited MUST reflect the amount of native tokens currently deposited into other contracts. All deposits and withdraws so update this variable.

  using SafeMath for uint256;

  address public alpacaVault;
  address public rebalancer;

  event UpdateRebalancer(address rebalancer);
  event UpdateAlpacaVault(address alpacaVault);

  constructor(
    address _fundsTarget,
    address _rebalancer,
    address _alpacaVault
  ) Strategy(_fundsTarget) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(REBALANCER_ROLE, msg.sender);
    rebalancer = payable(_rebalancer);
    alpacaVault = payable(_alpacaVault);
  }

  // Read Functions

  ///@notice The public checkRewards function MUST return a struct with the amount of pending rewards valued in native tokens, the total amount deposited, and the block timestamp.
  ///For example, if 500 NativeTokens are deposited, and the strategy has earned 5 Native Tokens and 2 of TokenA,
  ///the function should calculate the return for selling 2 TokenA, and add to the 5 Native Tokens.
  ///If we assume that each TokenA is worth 4 native tokens, then the unclaimedEarnings value should return a value of 13, adjusted for percision.

  function checkRewards() public view virtual override returns (IStrategy.Rewards memory) {
    uint256 pendingRewards = rewardsAmount();
    IStrategy.Rewards memory result = IStrategy.Rewards(
      pendingRewards,
      amountDeposited,
      block.timestamp * 1000
    );
    return result;
  }

  function getTotalSupplyBNB() public view returns (uint256 bNBSupply) {
    uint256 totalBNBSupply = IVault(alpacaVault).totalToken();
    return totalBNBSupply;
  }

  function getTotalSupplyIBNB() public view returns (uint256 ibBNBSupply) {
    uint256 totalIBBNBSupply = IERC20(alpacaVault).totalSupply();
    return totalIBBNBSupply;
  }

  function getIBBNBToBNB(uint256 ibBNBValue) public view returns (uint256 balance) {
    uint256 bnbSupply = getTotalSupplyBNB();
    uint256 ibBNBSupply = getTotalSupplyIBNB();
    uint256 ibbnbToBNB = (ibBNBValue.mul(bnbSupply)).div(ibBNBSupply);
    return ibbnbToBNB;
  }

  function getBNBToIBBNB(uint256 bnbValue) public view returns (uint256 balance) {
    uint256 bnbSupply = getTotalSupplyBNB();
    uint256 ibBNBSupply = getTotalSupplyIBNB();
    uint256 bnbToIBNB = (bnbValue.mul(ibBNBSupply)).div(bnbSupply);
    return bnbToIBNB;
  }

  ///@notice Returns Alpaca Balance in BNB
  function getAlpacaBalance() public view returns (uint256 balance) {
    uint256 ibBNBBalance = IERC20(alpacaVault).balanceOf(address(this));
    uint256 balanceInAlpaca = getIBBNBToBNB(ibBNBBalance);
    return balanceInAlpaca;
  }

  function rewardsAmount() public view returns (uint256 rewards) {
    uint256 redeemValue = getAlpacaBalance();
    uint256 pendingRewards = redeemValue.sub(amountDeposited);
    return pendingRewards;
  }

  // Write Functions
  ///@notice The withdrawAll function should withdraw all native tokens, including rewards as native tokens, and send them to the UP Controller.
  ///@return bool value will be false if undelegation is required first and is successful, value will be true if there is there is nothing to undelegate. All balance will be sen

  ///@notice The gather function should claim all yield earned from the native tokens while leaving the amount deposited intact.
  ///Then, this function should send all earnings to the rebalancer contract. This function MUST only send native tokens to the rebalancer.
  ///For example, if the tokens are deposited in a lending protocol, it should the totalBalance minus the amountDeposited.

  function gather() public virtual override onlyRebalancer whenNotPaused {
    uint256 toWithdraw = rewardsAmount();
    uint256 amountOfIBBNBToWithdraw = getBNBToIBBNB(toWithdraw);
    IERC20(alpacaVault).approve(alpacaVault, amountOfIBBNBToWithdraw);
    IVault(alpacaVault).withdraw(amountOfIBBNBToWithdraw);
    (bool successTransfer, ) = address(msg.sender).call{value: toWithdraw}("");
    require(successTransfer, "Alpaca Strategy: Fail sending funds to Rebalancer");
  }

  function deposit(uint256 depositValue)
    public
    payable
    virtual
    override
    onlyRebalancer
    whenNotPaused
    returns (bool)
  {
    require(
      depositValue == msg.value,
      "Alpaca Strategy: Deposit Value Parameter does not equal payable amount"
    );
    IVault(alpacaVault).deposit{value: depositValue}(depositValue);
    amountDeposited += depositValue;
    return true;
  }

  function withdraw(uint256 amount) public override onlyRebalancer whenNotPaused returns (bool) {
    require(
      amount <= amountDeposited,
      "Alpaca Strategy: Amount Requested to Withdraw is Greater Than Amount Deposited"
    );
    uint256 amountIBBNBWithdraw = getBNBToIBBNB(amount);
    IERC20(alpacaVault).approve(alpacaVault, amountIBBNBWithdraw);
    IVault(alpacaVault).withdraw(amountIBBNBWithdraw);
    (bool successTransfer, ) = address(msg.sender).call{value: amount}("");
    require(successTransfer, "Alpaca Strategy: Fail Sending Native to Rebalancer");
    amountDeposited -= amount;
    return true;
  }

  function withdrawAll() external virtual override onlyAdmin whenNotPaused returns (bool) {
    uint256 ibBNBBalance = IERC20(alpacaVault).balanceOf(address(this));
    IERC20(alpacaVault).approve(alpacaVault, ibBNBBalance);
    IVault(alpacaVault).withdraw(ibBNBBalance);
    (bool successTransfer, ) = address(msg.sender).call{value: address(this).balance}("");
    require(successTransfer, "Alpaca Strategy: Fail to Withdraw All from Alpaca");
    amountDeposited = 0;
    return successTransfer;
  }

  function setAlpacaVault(address newAddress) public onlyAdmin {
    alpacaVault = newAddress;
    emit UpdateAlpacaVault(newAddress);
  }
}
