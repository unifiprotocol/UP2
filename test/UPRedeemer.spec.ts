import { expect } from "chai"
import { BigNumber } from "ethers"
import { ethers } from "hardhat"
import { UP, UPController } from "../typechain-types"
import { UPRedeemer } from "../typechain-types/contracts/UPRedeemer"

describe("UPRedeemer", function () {
  let signerAddress: string
  let UP: UP
  let UPController: UPController
  let UPRedeemer: UPRedeemer

  let upBalance: BigNumber
  let totalValueLocked: BigNumber

  beforeEach(async () => {
    const _signerAddress = await ethers.getSigners().then(([signer]) => signer.getAddress())
    signerAddress = _signerAddress

    UP = await ethers.getContractFactory("UP").then((cf) => cf.deploy())
    UPController = await ethers
      .getContractFactory("UPController")
      .then((cf) => cf.deploy(UP.address, signerAddress))
    UPRedeemer = await ethers
      .getContractFactory("UPRedeemer")
      .then((cf) => cf.deploy(UP.address, UPController.address, signerAddress))

    const MINT_ROLE = await UP.MINT_ROLE()
    await UP.grantRole(MINT_ROLE, signerAddress)

    const OWNER_ROLE = await UPRedeemer.OWNER_ROLE()
    await UPRedeemer.grantRole(OWNER_ROLE, signerAddress)

    const _totalValueLocked = "0xde0b6b3a7640000"
    totalValueLocked = BigNumber.from(_totalValueLocked)

    await ethers.provider.send("hardhat_setBalance", [UPController.address, _totalValueLocked])

    upBalance = BigNumber.from("0xde0b6b3a764000")
    await UP.mint(signerAddress, upBalance)
  })

  describe("constructor", () => {
    it("should fail UP = address(0)", async () => {
      const redeemerFactory = await ethers.getContractFactory("UPRedeemer")

      await expect(
        redeemerFactory.deploy(ethers.constants.AddressZero, signerAddress, signerAddress)
      ).to.be.revertedWith("UPRedeemer: INVALID_UP_ADDRESS")
    })

    it("should fail UPController = address(0)", async () => {
      const redeemerFactory = await ethers.getContractFactory("UPRedeemer")

      await expect(
        redeemerFactory.deploy(signerAddress, ethers.constants.AddressZero, signerAddress)
      ).to.be.revertedWith("UPRedeemer: INVALID_UP_CONTROLLER_ADDRESS")
    })

    it("should deploy UPRedeemer successfully", async () => {
      const redeemerFactory = await ethers.getContractFactory("UPRedeemer")

      await redeemerFactory.deploy(signerAddress, signerAddress, signerAddress)
    })
  })

  describe("Safe", function () {
    it("should fail withdrawFunds without permission", async () => {
      const [, signer2] = await ethers.getSigners()

      const OWNER_ROLE = await UPRedeemer.OWNER_ROLE()

      await expect(UPRedeemer.connect(signer2).withdrawFunds()).to.be.revertedWith(
        `is missing role ${OWNER_ROLE}`
      )
    })
    it("should fail withdrawFundsERC20 without permission", async () => {
      const [, signer2] = await ethers.getSigners()

      const OWNER_ROLE = await UPRedeemer.OWNER_ROLE()

      await expect(UPRedeemer.connect(signer2).withdrawFundsERC20(UP.address)).to.be.revertedWith(
        `is missing role ${OWNER_ROLE}`
      )
    })
    it("should withdraw ETH balance", async () => {
      const depositedAmount = BigNumber.from("1000")

      await ethers.provider.send("hardhat_setBalance", [
        UPRedeemer.address,
        depositedAmount.toHexString().replace(/^0x0+/, "0x")
      ])

      const OWNER_ROLE = await UPRedeemer.OWNER_ROLE()
      await UPRedeemer.grantRole(OWNER_ROLE, signerAddress)

      const prevUserBalance = await ethers.provider.getBalance(signerAddress)

      const totalFees = await UPRedeemer.withdrawFunds()
        .then((trx) => trx.wait())
        .then((receipt) => receipt.gasUsed.mul(receipt.effectiveGasPrice))

      const postUserBalance = await ethers.provider.getBalance(signerAddress)

      expect(depositedAmount).not.be.equal(0, "DEPOSITED_AMOUNT should be greater than zero")
      expect(prevUserBalance.add(depositedAmount).sub(totalFees)).to.be.equal(
        postUserBalance,
        "BALANCES DONT MATCH"
      )
    })
    it("should withdraw UP balance", async () => {
      const upAmount = upBalance

      await UP.transfer(UPRedeemer.address, upAmount)

      const OWNER_ROLE = await UPRedeemer.OWNER_ROLE()
      await UPRedeemer.grantRole(OWNER_ROLE, signerAddress)

      await UPRedeemer.withdrawFundsERC20(UP.address)

      expect(await UP.balanceOf(signerAddress)).to.be.equal(upAmount)
    })
  })

  describe("Pausable", function () {
    it("should fail pausing contract due to lack of permission", async () => {
      const [, signer2] = await ethers.getSigners()

      const OWNER_ROLE = await UPRedeemer.OWNER_ROLE()

      await expect(UPRedeemer.connect(signer2).pause()).to.be.revertedWith(
        `is missing role ${OWNER_ROLE}`
      )
    })

    it("should fail unpausing contract due to lack of permission", async () => {
      const [, signer2] = await ethers.getSigners()

      const OWNER_ROLE = await UPRedeemer.OWNER_ROLE()

      await UPRedeemer.pause()
      await expect(UPRedeemer.connect(signer2).unpause()).to.be.revertedWith(
        `is missing role ${OWNER_ROLE}`
      )
    })

    it("should fail pausing contract", async () => {
      await UPRedeemer.pause()
      expect(await UPRedeemer.paused()).to.be.equal(true)
      await UPRedeemer.unpause()
      expect(await UPRedeemer.paused()).to.be.equal(false)
    })
  })

  describe("Redeem", function () {
    it("should fail without allowance", async () => {
      await expect(UPRedeemer.redeem(upBalance.div(10))).to.be.revertedWith(
        "ERC20: insufficient allowance"
      )
    })

    it("should fail without REDEEMER_ROLE", async () => {
      await UP.approve(UPRedeemer.address, upBalance)
      await expect(UPRedeemer.redeem(upBalance.div(10))).to.be.revertedWith(
        "UPController: ONLY_REDEEMER"
      )
    })

    it("should pause contract and fail redeem", async () => {
      await UPRedeemer.pause()
      expect(await UPRedeemer.paused()).to.be.equal(true)
      await expect(UPRedeemer.redeem(upBalance.div(10))).to.be.revertedWith("Pausable: paused")
    })

    it("should fail when there is no funds in UPController", async () => {
      const REBALANCER_ROLE = await UPController.REBALANCER_ROLE()

      await UPController.grantRole(REBALANCER_ROLE, signerAddress)
      await UPController.borrowNative(totalValueLocked, signerAddress)

      await UP.approve(UPRedeemer.address, upBalance)
      const REDEEMER_ROLE = await UPController.REDEEMER_ROLE()
      await UPController.grantRole(REDEEMER_ROLE, UPRedeemer.address)

      await expect(UPRedeemer.redeem(upBalance)).to.be.revertedWith("UPController: REDEEM_FAILED")
    })

    it("should fail if burned UP reedeemable amount is zero", async () => {
      await UP.approve(UPRedeemer.address, upBalance)

      const REDEEMER_ROLE = await UPController.REDEEMER_ROLE()
      await UPController.grantRole(REDEEMER_ROLE, UPRedeemer.address)

      const upRedeemAmount = BigNumber.from(1)

      await ethers.provider.send("hardhat_setBalance", [
        UPController.address,
        upBalance.div(1000).toHexString()
      ])

      await expect(UPRedeemer.redeem(upRedeemAmount)).to.be.revertedWith(
        "UPRedeemer: NOT_ENOUGH_UP_REDEEMED"
      )
    })

    it("should fail if send native to user fails", async () => {
      const REDEEMER_ROLE = await UPController.REDEEMER_ROLE()

      await UPController.grantRole(REDEEMER_ROLE, UPRedeemer.address)

      const nonPayableContract = await ethers
        .getContractFactory("NonPayableContract")
        .then((cf) => cf.deploy(UP.address, UPRedeemer.address))
      await UP.transfer(nonPayableContract.address, upBalance)

      await expect(nonPayableContract.redeem()).to.be.revertedWith(
        "UPRedeemer: FAIL_SENDING_NATIVE"
      )
    })

    it("should fail redeeming more than actual balance", async () => {
      await UP.approve(UPRedeemer.address, upBalance.mul(2))
      const REDEEMER_ROLE = await UPController.REDEEMER_ROLE()
      await UPController.grantRole(REDEEMER_ROLE, UPRedeemer.address)

      const upRedeemAmount = upBalance.mul(2)

      await expect(UPRedeemer.redeem(upRedeemAmount)).to.be.revertedWith(
        "ERC20: transfer amount exceeds balance"
      )
    })

    it("should execute partial redeem successfully", async () => {
      await UP.approve(UPRedeemer.address, upBalance)

      const REDEEMER_ROLE = await UPController.REDEEMER_ROLE()
      await UPController.grantRole(REDEEMER_ROLE, UPRedeemer.address)

      const backedValue = await UPController["getVirtualPrice()"]()
      const upRedeemAmount = upBalance.div(10)
      const expectedNativeRedeemedAmount = backedValue
        .mul(upRedeemAmount)
        .div(BigNumber.from(10).pow(18))

      const previousBalance = await ethers.provider.getBalance(signerAddress)

      const trxFees = await UPRedeemer.redeem(upRedeemAmount)
        .then((trx) => {
          expect(trx).to.have.emit(UPRedeemer.address, "Redeem")
          return trx.wait()
        })
        .then((receipt) => receipt.gasUsed.mul(receipt.effectiveGasPrice))

      const postBalance = await ethers.provider.getBalance(signerAddress)

      expect(previousBalance.add(expectedNativeRedeemedAmount).sub(trxFees)).to.be.equals(
        postBalance
      )
    })

    it("should execute full redeem successfully", async () => {
      await UP.approve(UPRedeemer.address, upBalance)

      const REDEEMER_ROLE = await UPController.REDEEMER_ROLE()
      await UPController.grantRole(REDEEMER_ROLE, UPRedeemer.address)

      const backedValue = await UPController["getVirtualPrice()"]()
      const upRedeemAmount = upBalance
      const expectedNativeRedeemedAmount = backedValue
        .mul(upRedeemAmount)
        .div(BigNumber.from(10).pow(18))

      const previousBalance = await ethers.provider.getBalance(signerAddress)

      const trxFees = await UPRedeemer.redeem(upRedeemAmount)
        .then((trx) => {
          expect(trx).to.have.emit(UPRedeemer.address, "Redeem")
          return trx.wait()
        })
        .then((receipt) => receipt.gasUsed.mul(receipt.effectiveGasPrice))

      const postBalance = await ethers.provider.getBalance(signerAddress)

      expect(previousBalance.add(expectedNativeRedeemedAmount).sub(trxFees)).to.be.equals(
        postBalance
      )
    })

    it("should execute small amount redeem successfully", async () => {
      await UP.approve(UPRedeemer.address, upBalance)

      const REDEEMER_ROLE = await UPController.REDEEMER_ROLE()
      await UPController.grantRole(REDEEMER_ROLE, UPRedeemer.address)

      const backedValue = await UPController["getVirtualPrice()"]()
      const upRedeemAmount = BigNumber.from(1000)
      const expectedNativeRedeemedAmount = backedValue
        .mul(upRedeemAmount)
        .div(BigNumber.from(10).pow(18))

      const previousBalance = await ethers.provider.getBalance(signerAddress)

      const trxFees = await UPRedeemer.redeem(upRedeemAmount)
        .then((trx) => {
          expect(trx).to.have.emit(UPRedeemer.address, "Redeem")
          return trx.wait()
        })
        .then((receipt) => receipt.gasUsed.mul(receipt.effectiveGasPrice))

      const postBalance = await ethers.provider.getBalance(signerAddress)

      expect(previousBalance.add(expectedNativeRedeemedAmount).sub(trxFees)).to.be.equals(
        postBalance
      )
    })
  })

  describe("Update UPController", function () {
    it("should fail to update when not owner", async () => {
      const [, signer2] = await ethers.getSigners()

      const OWNER_ROLE = await UPRedeemer.OWNER_ROLE()

      await expect(
        UPRedeemer.connect(signer2).updateUPController(signerAddress)
      ).to.be.revertedWith(`is missing role ${OWNER_ROLE}`)
    })

    it("should update up controller address", async () => {
      expect(await UPRedeemer.updateUPController(signerAddress)).to.have.emit(
        UPRedeemer.address,
        "UpdateUPController"
      )
      expect(await UPRedeemer.UP_CONTROLLER()).to.be.equal(signerAddress)
    })
  })
})
