import { expect } from "chai"
import { ethers } from "hardhat"
import { Rebalancer } from "../typechain-types"

describe("Rebalancer", function () {
  let rebalancer: Rebalancer
  let unpermissionedRebalancer: Rebalancer

  beforeEach(async () => {
    const [, unpermissionedAccount] = await ethers.getSigners()
    const libAddress = await ethers
      .getContractFactory("UniswapHelper")
      .then((cf) => cf.deploy())
      .then(({ address }) => address)
    rebalancer = await ethers
      .getContractFactory("Rebalancer", {
        libraries: {
          UniswapHelper: libAddress
        }
      })
      .then((cf) =>
        cf.deploy(
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          ethers.constants.AddressZero,
          ethers.constants.AddressZero
        )
      )
    unpermissionedRebalancer = rebalancer.connect(unpermissionedAccount)
  })

  describe("getters and setters", function () {
    it("setUPController should change upController", async () => {
      await rebalancer.setUPController(rebalancer.address)
      expect(await rebalancer.UP_CONTROLLER()).equals(rebalancer.address)
    })
    it("setUPController should fail from an unpermissioned account", async () => {
      await expect(unpermissionedRebalancer.setUPController(rebalancer.address)).to.revertedWith(
        "ONLY_ADMIN"
      )
    })
    it("setStrategy should change upController", async () => {
      await rebalancer.setStrategy(rebalancer.address)
      expect(await rebalancer.strategy()).equals(rebalancer.address)
    })
    it("setStrategy should fail from an unpermissioned account", async () => {
      await expect(unpermissionedRebalancer.setStrategy(rebalancer.address)).to.revertedWith(
        "ONLY_ADMIN"
      )
    })
    it("setAllocationLP should change allocationLp", async () => {
      await rebalancer.setAllocationLP(5)
      expect(await rebalancer.allocationLP()).equals(5)
    })
    it("setAllocationLP should fail from an unpermissioned account", async () => {
      await expect(unpermissionedRebalancer.setAllocationLP(5)).to.revertedWith("ONLY_ADMIN")
    })
    it("setAllocationRedeem should change allocationRedeem", async () => {
      await rebalancer.setAllocationRedeem(5)
      expect(await rebalancer.allocationRedeem()).equals(5)
    })
    it("setAllocationRedeem should fail from an unpermissioned account", async () => {
      await expect(unpermissionedRebalancer.setAllocationRedeem(5)).to.revertedWith("ONLY_ADMIN")
    })
    it("setSlippageTolerance should change slippage tolerance", async () => {
      await rebalancer.setSlippageTolerance(5)
      expect(await rebalancer.slippageTolerance()).equals(5)
    })
    it("setAllocationLP should fail from an unpermissioned account", async () => {
      await expect(unpermissionedRebalancer.setSlippageTolerance(5)).to.revertedWith("ONLY_ADMIN")
    })
    it("setAllocationLP should fail with invalid amounts", async () => {
      await expect(rebalancer.setSlippageTolerance(100_000)).to.revertedWith(
        "Cannot Set Slippage Tolerance over 100%"
      )
    })
  })
})
