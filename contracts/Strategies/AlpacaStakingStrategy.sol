// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Strategy.sol";
import "./Interfaces/IVault.sol";

// Contract Strategy must use our customized Safe.sol and OpenZeppelin's AccessControl and Pauseable Contracts.
// Safe.sol is utilized so the DAO can retrieve any lost assets within the Strategy Contract.
// AccessControl.sol is utilized so only the Rebalancer can interact with the strategy, and only the DAO can update the Rebalancer Contract.
// Pausable.sol is utilized so that DAO can pause the strategy in an emergency.

contract AlpacaBNBStrategy is Strategy {
  address public alpacaVault;

  event UpdateAlpacaVault(address alpacaVault);

  constructor(address _fundsTarget, address _alpacaVault) Strategy(_fundsTarget) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(REBALANCER_ROLE, msg.sender);
    alpacaVault = payable(_alpacaVault);
  }

  // Read Functions

  ///@notice Returns the current amount of pending rewards, the amount of BNB deposited into the Alpaca contract, and the current timestamp.
  function checkRewards() public view virtual override returns (Strategy.Rewards memory) {
    uint256 pendingRewards = rewardsAmount();
    Strategy.Rewards memory result = Strategy.Rewards(
      pendingRewards,
      amountDeposited,
      block.timestamp * 1000
    );
    return result;
  }

  ///@notice Gets total amount of BNB held by Alpaca globally. Used to determine redemption value of ibBNB.
  function getTotalSupplyBNB() public view returns (uint256 bNBSupply) {
    uint256 totalBNBSupply = IVault(alpacaVault).totalToken();
    return totalBNBSupply;
  }

  ///@notice Gets total amount of ibBNB in existance. Used to determine redemption value of ibBNB.
  function getTotalSupplyIBNB() public view returns (uint256 ibBNBSupply) {
    uint256 totalIBBNBSupply = IERC20(alpacaVault).totalSupply();
    return totalIBBNBSupply;
  }

  ///@notice Takes an amount of ibBNB and calculates the amount of BNB it can be redeemed for.
  function getIBBNBToBNB(uint256 ibBNBValue) public view returns (uint256 balance) {
    uint256 bnbSupply = getTotalSupplyBNB();
    uint256 ibBNBSupply = getTotalSupplyIBNB();
    uint256 ibbnbToBNB = (ibBNBValue * bnbSupply) / ibBNBSupply;
    return ibbnbToBNB;
  }

  ///@notice Takes an amount of BNB and calculates the amount of ibBNB it can converted to.
  function getBNBToIBBNB(uint256 bnbValue) public view returns (uint256 balance) {
    uint256 bnbSupply = getTotalSupplyBNB();
    uint256 ibBNBSupply = getTotalSupplyIBNB();
    uint256 bnbToIBNB = (bnbValue * ibBNBSupply) / bnbSupply;
    return bnbToIBNB;
  }

  ///@notice Returns the strategy's current amount of BNB, including rewards, earning yield on Alpaca.
  function getAlpacaBalance() public view returns (uint256 balance) {
    uint256 ibBNBBalance = IERC20(alpacaVault).balanceOf(address(this));
    uint256 balanceInAlpaca = getIBBNBToBNB(ibBNBBalance);
    return balanceInAlpaca;
  }

  ///@notice Returns the strategy's current amount of pending rewards in Alpaca.
  function rewardsAmount() public view returns (uint256 rewards) {
    uint256 redeemValue = getAlpacaBalance();
    uint256 pendingRewards = redeemValue - amountDeposited;
    return pendingRewards;
  }

  // Write Functions

  ///@notice Calculates the amount of rewards pending, and redeems the approporiate amount of ibBNB to receive those rewards in BNB. Then, sends the amount of BNB in the strategy's wallet to the rebalancer.
  function gather() public virtual override onlyRebalancer whenNotPaused {
    uint256 toWithdraw = rewardsAmount();
    uint256 amountOfIBBNBToWithdraw = getBNBToIBBNB(toWithdraw);
    IERC20(alpacaVault).approve(alpacaVault, amountOfIBBNBToWithdraw);
    IVault(alpacaVault).withdraw(amountOfIBBNBToWithdraw);
    (bool successTransfer, ) = address(msg.sender).call{value: address(this).balance}("");
    require(successTransfer, "Alpaca Strategy: Fail sending funds to Rebalancer");
  }

  ///@notice Deposits funds sent from the rebalancer into Alpaca
  function deposit(
    uint256 depositValue
  ) public payable virtual override onlyRebalancer whenNotPaused returns (bool) {
    require(
      depositValue == msg.value,
      "Alpaca Strategy: Deposit Value Parameter does not equal payable amount"
    );
    IVault(alpacaVault).deposit{value: depositValue}(depositValue);
    amountDeposited += depositValue;
    return true;
  }

  ///@notice Withdraws funds Alpaca to send to the rebalancer
  function withdraw(uint256 amount) public override onlyRebalancer whenNotPaused returns (bool) {
    require(
      amount <= amountDeposited,
      "Alpaca Strategy: Amount Requested to Withdraw is Greater Than Amount Deposited"
    );
    uint256 amountIBBNBWithdraw = getBNBToIBBNB(amount);
    IERC20(alpacaVault).approve(alpacaVault, amountIBBNBWithdraw);
    IVault(alpacaVault).withdraw(amountIBBNBWithdraw);
    (bool successTransfer, ) = address(msg.sender).call{value: address(this).balance}("");
    require(successTransfer, "Alpaca Strategy: Fail Sending Native to Rebalancer");
    amountDeposited -= amount;
    return true;
  }

  ///@notice Withdraws ALL funds Alpaca to send to the rebalancer
  function withdrawAll() external virtual override onlyRebalancer whenNotPaused returns (bool) {
    uint256 ibBNBBalance = IERC20(alpacaVault).balanceOf(address(this));
    IERC20(alpacaVault).approve(alpacaVault, ibBNBBalance);
    IVault(alpacaVault).withdraw(ibBNBBalance);
    (bool successTransfer, ) = address(msg.sender).call{value: address(this).balance}("");
    require(successTransfer, "Alpaca Strategy: Fail to Withdraw All from Alpaca");
    amountDeposited = 0;
    return successTransfer;
  }

  ///@notice Changes the address of the Alpaca Vault
  function setAlpacaVault(address newAddress) public onlyAdmin {
    alpacaVault = newAddress;
    emit UpdateAlpacaVault(newAddress);
  }
}
