import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { Darbi, UP, UPController, UPMintDarbi } from "../../typechain-types"
import { expect } from "chai"
import { ethers } from "hardhat"

describe("Darbi", () => {
  let darbiContract: Darbi
  let unpermissionedDarbiContract: Darbi
  let admin
  let unpermissionedAccount: SignerWithAddress
  const MEANINGLESS_ADDRESS = "0xA38395b264f232ffF4bb294b5947092E359dDE88"
  const MEANINGLESS_AMOUNT = "10000"

  beforeEach(async () => {
    const lib = await ethers.getContractFactory("UniswapHelper").then((cf) => cf.deploy())

    const UP_CONTROLLER = await ethers
      .getContractFactory("UPController")
      .then((cf) => cf.deploy(MEANINGLESS_ADDRESS))

    const DarbiFactory = await ethers.getContractFactory("Darbi", {
      libraries: {
        UniswapHelper: lib.address
      }
    })

    const [_admin, _unpermissionedAccount] = await ethers.getSigners()

    admin = _admin
    unpermissionedAccount = _unpermissionedAccount

    darbiContract = await DarbiFactory.deploy(
      ethers.constants.AddressZero,
      ethers.constants.AddressZero,
      ethers.constants.AddressZero,
      ethers.constants.AddressZero,
      UP_CONTROLLER.address,
      ethers.constants.AddressZero,
      MEANINGLESS_AMOUNT,
      MEANINGLESS_AMOUNT
    )

    unpermissionedDarbiContract = darbiContract.connect(unpermissionedAccount)
  })

  describe("getters and setters", async () => {
    it("setFactory should fail due to unpermissioned account", async () => {
      await expect(unpermissionedDarbiContract.setFactory(MEANINGLESS_ADDRESS)).to.be.reverted
    })
    it("setFactory should fail due to invalid address (zero)", async () => {
      await expect(darbiContract.setFactory(ethers.constants.AddressZero)).to.be.reverted
    })
    it("setFactory should change factory contract address", async () => {
      await darbiContract.setFactory(MEANINGLESS_ADDRESS)
      expect(await darbiContract.factory()).equal(
        MEANINGLESS_ADDRESS,
        "Factory address should have been changed"
      )
    })
    it("setRouter should fail due to unpermissioned account", async () => {
      await expect(unpermissionedDarbiContract.setRouter(MEANINGLESS_ADDRESS)).to.be.reverted
    })
    it("setRouter should fail due to invalid address (zero)", async () => {
      await expect(darbiContract.setRouter(ethers.constants.AddressZero)).to.be.reverted
    })
    it("setRouter should change router contract address", async () => {
      await darbiContract.setRouter(MEANINGLESS_ADDRESS)
      expect(await darbiContract.router()).equal(
        MEANINGLESS_ADDRESS,
        "Router address should have been changed"
      )
    })
    it("setDarbiMinter should fail due to unpermissioned account", async () => {
      await expect(unpermissionedDarbiContract.setDarbiMinter(MEANINGLESS_ADDRESS)).to.be.reverted
    })
    it("setDarbiMinter should fail due to invalid address (zero)", async () => {
      await expect(darbiContract.setDarbiMinter(ethers.constants.AddressZero)).to.be.reverted
    })
    it("setDarbiMinter should change darbi minter contract address", async () => {
      await darbiContract.setDarbiMinter(MEANINGLESS_ADDRESS)
      expect(await darbiContract.DARBI_MINTER()).equal(
        MEANINGLESS_ADDRESS,
        "Darbi minter address should have been changed"
      )
    })
    it("setArbitrageThreshold should fail due to unpermissioned account", async () => {
      await expect(unpermissionedDarbiContract.setArbitrageThreshold(0)).to.be.reverted
    })
    it("setArbitrageThreshold should fail due to invalid amount (zero)", async () => {
      await expect(darbiContract.setArbitrageThreshold(0)).to.be.reverted
    })
    it("setArbitrageThreshold should change arbitrage threshold", async () => {
      await darbiContract.setArbitrageThreshold(MEANINGLESS_AMOUNT)
      expect(await darbiContract.arbitrageThreshold()).equals(
        MEANINGLESS_AMOUNT,
        "Arbitrage threshold should have been changed"
      )
    })
    it("setGasRefund should fail due to unpermissioned account", async () => {
      await expect(unpermissionedDarbiContract.setGasRefund(MEANINGLESS_AMOUNT)).to.be.reverted
    })
    it("setGasRefund should fail due to invalid amount (zero)", async () => {
      await expect(darbiContract.setGasRefund(0)).to.be.reverted
    })
    it("setGasRefund should change gas refund amount", async () => {
      await darbiContract.setGasRefund(MEANINGLESS_AMOUNT)
      expect(await darbiContract.gasRefund()).equals(MEANINGLESS_AMOUNT)
    })
  })

  describe("arbitrage", async () => {
    it("should be able to call arbitrage function monitor and notPaused", async () => {
      let promise = darbiContract.arbitrage()
      await expect(promise).not.to.revertedWith("ONLY_MONITOR")
      await expect(promise).not.to.revertedWith("Pausable: paused")
    })
    it("should not be able to call arbitrage function unpermissioned account until its assigned monitor role", async () => {
      await expect(unpermissionedDarbiContract.arbitrage()).to.revertedWith("ONLY_MONITOR")
      const MONITOR_ROLE = await darbiContract.MONITOR_ROLE()
      await darbiContract.grantRole(MONITOR_ROLE, unpermissionedAccount.address)
      const promise = unpermissionedDarbiContract.arbitrage()
      await expect(promise).not.to.revertedWith("ONLY_MONITOR")
      await expect(promise).not.to.revertedWith("Pausable: paused")
    })
    it("should not be able to call arbitrage function while its paused", async () => {
      await darbiContract.pause()
      await expect(darbiContract.arbitrage()).not.to.revertedWith("ONLY_MONITOR")
      await expect(darbiContract.arbitrage()).to.revertedWith("Pausable: paused")
      await darbiContract.unpause()
      await expect(darbiContract.arbitrage()).not.to.revertedWith("ONLY_MONITOR")
      await expect(darbiContract.arbitrage()).not.to.revertedWith("Pausable: paused")
    })
  })
})
