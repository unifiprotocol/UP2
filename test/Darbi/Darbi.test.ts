import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import {
  Darbi,
  IUniswapV2Pair__factory,
  IUniswapV2Router02,
  UniswapHelper,
  UP,
  UPController,
  UPMintDarbi
} from "../../typechain-types"
import { expect } from "chai"
import { ethers } from "hardhat"
import contracts from "../Contracts"
import { getUniswapRouter } from "../Helper"
import { BN } from "@unifiprotocol/utils"

describe("Darbi", async () => {
  let darbiContract: Darbi
  let unpermissionedDarbiContract: Darbi
  let admin: SignerWithAddress
  let unpermissionedAccount: SignerWithAddress
  let UP_TOKEN: UP
  let UNISWAP_HELPER: UniswapHelper
  let UP_CONTROLLER: UPController
  let UP_MINT_DARBI: UPMintDarbi
  const MEANINGLESS_ADDRESS = "0xA38395b264f232ffF4bb294b5947092E359dDE88"
  const MEANINGLESS_AMOUNT = "10000"

  beforeEach(async () => {
    const [_admin, _unpermissionedAccount] = await ethers.getSigners()
    admin = _admin
    unpermissionedAccount = _unpermissionedAccount

    UNISWAP_HELPER = await ethers.getContractFactory("UniswapHelper").then((cf) => cf.deploy())

    UP_TOKEN = await ethers
      .getContractFactory("UP")
      .then((factory) => factory.deploy())
      .then((instance) => instance.deployed())
    UP_CONTROLLER = await ethers
      .getContractFactory("UPController")
      .then((cf) => cf.deploy(UP_TOKEN.address))

    await admin.sendTransaction({
      to: UP_CONTROLLER.address,
      value: ethers.utils.parseEther("5")
    })
    await UP_TOKEN.grantRole(await UP_TOKEN.MINT_ROLE(), admin.address)
    await UP_TOKEN.mint(admin.address, ethers.utils.parseEther("2"))

    UP_MINT_DARBI = await ethers
      .getContractFactory("UPMintDarbi")
      .then((factory) => factory.deploy(UP_TOKEN.address, UP_CONTROLLER.address))
      .then((instance) => instance.deployed())

    await UP_TOKEN.grantRole(await UP_TOKEN.MINT_ROLE(), UP_MINT_DARBI.address)
    await UP_TOKEN.grantRole(await UP_TOKEN.MINT_ROLE(), UP_CONTROLLER.address)

    const DarbiFactory = await ethers.getContractFactory("Darbi", {
      libraries: {
        UniswapHelper: UNISWAP_HELPER.address
      }
    })

    darbiContract = await DarbiFactory.deploy(
      contracts["Factory"],
      contracts["Router"],
      contracts["WETH"],
      admin.address,
      UP_CONTROLLER.address,
      UP_MINT_DARBI.address,
      MEANINGLESS_AMOUNT
    )

    await admin.sendTransaction({
      to: darbiContract.address,
      value: ethers.utils.parseEther("5")
    })

    unpermissionedDarbiContract = darbiContract.connect(unpermissionedAccount)
  })

  describe("getters and setters", async () => {
    it("setDarbiMinter should fail due to unpermissioned account", async () => {
      await expect(unpermissionedDarbiContract.setDarbiMinter(MEANINGLESS_ADDRESS)).to.be.reverted
    })
    it("setDarbiMinter should fail due to invalid address (zero)", async () => {
      await expect(darbiContract.setDarbiMinter(ethers.constants.AddressZero)).to.be.reverted
    })
    it("setController should fail due to unpermissioned account", async () => {
      await expect(unpermissionedDarbiContract.setController(MEANINGLESS_ADDRESS)).to.be.reverted
    })
    it("setController should fail due to invalid address (zero)", async () => {
      await expect(darbiContract.setController(ethers.constants.AddressZero)).to.be.reverted
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

  describe("moveMarketBuyAmount", () => {
    let router: IUniswapV2Router02
    beforeEach(async () => {
      // Create pool
      router = await getUniswapRouter(contracts["Router"])
      await UP_TOKEN.approve(router.address, ethers.utils.parseEther("10000"))
      await router.addLiquidityETH(
        UP_TOKEN.address,
        ethers.utils.parseEther("2"),
        0,
        0,
        admin.address,
        Date.now() + 150,
        { value: ethers.utils.parseEther("5") }
      )

      const DarbiFactory = await ethers.getContractFactory("Darbi", {
        libraries: {
          UniswapHelper: UNISWAP_HELPER.address
        }
      })

      darbiContract = await DarbiFactory.deploy(
        contracts["Factory"],
        contracts["Router"],
        contracts["WETH"],
        admin.address,
        UP_CONTROLLER.address,
        UP_MINT_DARBI.address,
        MEANINGLESS_AMOUNT
      )
    })

    it("Should return amountIn zero because the pool is aligned", async () => {
      const { aToB, amountIn } = await darbiContract.moveMarketBuyAmount()
      expect(aToB).equals(false)
      expect(amountIn).equals(0)
    })

    it("Should return an amountIn enough for aligning the price of the LP <1% increasing the UP circulation supply", async () => {
      await UP_TOKEN.mint(admin.address, ethers.utils.parseEther("1"))
      const virtualPrice = await UP_CONTROLLER["getVirtualPrice()"]().then((res) =>
        BN(res.toHexString())
      )
      const { aToB, amountIn } = await darbiContract.moveMarketBuyAmount()
      await router.swapExactTokensForETH(
        amountIn,
        0,
        [UP_TOKEN.address, contracts["WETH"]],
        admin.address,
        Date.now()
      )
      const { reserveA, reserveB } = await UNISWAP_HELPER.getReserves(
        contracts["Factory"],
        contracts["WETH"],
        UP_TOKEN.address
      )
      const newPrice = BN(reserveA.toHexString())
        .div(reserveB.toHexString())
        .multipliedBy(ethers.utils.parseEther("1").toHexString())
      const diff = BN(1).minus(newPrice.dividedBy(virtualPrice))
      const diffPercentage = diff.multipliedBy(100).dp(4).abs().toNumber()
      expect(aToB).equals(true)
      expect(diffPercentage).lessThan(1) // 1% of difference
    })

    it("Should return an amountIn enough for aligning the price of the LP <1% increasing the NativeToken backing UP", async () => {
      await admin.sendTransaction({
        to: UP_CONTROLLER.address,
        value: ethers.utils.parseEther("6") // New balance = 11 ETH / 2 UP
      })
      const virtualPrice = await UP_CONTROLLER["getVirtualPrice()"]().then((res) =>
        BN(res.toHexString())
      )
      const { aToB, amountIn } = await darbiContract.moveMarketBuyAmount()
      await router.swapExactETHForTokens(
        0,
        [contracts["WETH"], UP_TOKEN.address],
        admin.address,
        Date.now(),
        { value: amountIn }
      )
      const { reserveA, reserveB } = await UNISWAP_HELPER.getReserves(
        contracts["Factory"],
        contracts["WETH"],
        UP_TOKEN.address
      )
      const newPrice = BN(reserveA.toHexString())
        .div(reserveB.toHexString())
        .multipliedBy(ethers.utils.parseEther("1").toHexString())
      const diff = BN(1).minus(newPrice.dividedBy(virtualPrice))
      const diffPercentage = diff.multipliedBy(100).dp(4).abs().toNumber()
      expect(aToB).equals(false)
      expect(diffPercentage).lessThan(1) // 1% of difference
    })
  })

  describe("arbitrage", async () => {
    beforeEach(async () => {
      // Create pool
      const router = await getUniswapRouter(contracts["Router"])
      await UP_TOKEN.approve(router.address, ethers.utils.parseEther("10000"))
      await router.addLiquidityETH(
        UP_TOKEN.address,
        ethers.utils.parseEther("2"),
        0,
        0,
        admin.address,
        Date.now() + 150,
        { value: ethers.utils.parseEther("5") }
      )

      const DarbiFactory = await ethers.getContractFactory("Darbi", {
        libraries: {
          UniswapHelper: UNISWAP_HELPER.address
        }
      })

      darbiContract = await DarbiFactory.deploy(
        contracts["Factory"],
        contracts["Router"],
        contracts["WETH"],
        admin.address,
        UP_CONTROLLER.address,
        UP_MINT_DARBI.address,
        MEANINGLESS_AMOUNT
      )

      await admin.sendTransaction({
        to: darbiContract.address,
        value: ethers.utils.parseEther("30")
      })

      await UP_MINT_DARBI.grantDarbiRole(darbiContract.address)
      await UP_CONTROLLER.grantRole(await UP_CONTROLLER.REDEEMER_ROLE(), darbiContract.address)
      unpermissionedDarbiContract = darbiContract.connect(unpermissionedAccount)
    })

    it("should be able to call arbitrage function monitor and notPaused", async () => {
      await darbiContract.grantRole(await darbiContract.MONITOR_ROLE(), admin.address)
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
      await expect(darbiContract.arbitrage()).to.revertedWith("Pausable: paused")
      await darbiContract.unpause()
      await expect(darbiContract.arbitrage()).not.to.revertedWith("Pausable: paused")
    })

    it("should return an amountIn enough for aligning the price of the LP <1% increasing the UP circulation supply", async () => {
      await UP_TOKEN.mint(admin.address, ethers.utils.parseEther("1"))
      const virtualPrice = await UP_CONTROLLER["getVirtualPrice()"]().then((res) =>
        BN(res.toHexString())
      )
      await darbiContract.arbitrage()
      const { reserveA, reserveB } = await UNISWAP_HELPER.getReserves(
        contracts["Factory"],
        contracts["WETH"],
        UP_TOKEN.address
      )
      const newPrice = BN(reserveA.toHexString())
        .div(reserveB.toHexString())
        .multipliedBy(ethers.utils.parseEther("1").toHexString())
      const diff = BN(1).minus(newPrice.dividedBy(virtualPrice))
      const diffPercentage = diff.multipliedBy(100).dp(4).abs().toNumber()
      expect(diffPercentage).lessThan(1) // 1% of difference
    })

    it("should try to match LP price to UPC virtual price. refund to be processed", async () => {
      await UP_TOKEN.mint(admin.address, ethers.utils.parseEther("10"))
      const ethAmount = ethers.utils.parseEther("1")

      await darbiContract.setDarbiFunds(ethers.utils.parseEther("1"))
      await darbiContract.withdrawFunds(admin.address)
      await admin.sendTransaction({
        to: darbiContract.address,
        value: ethAmount
      })

      await darbiContract.arbitrage()

      expect(await ethers.provider.getBalance(darbiContract.address)).to.be.equal(
        ethers.utils.parseEther("1")
      )
    })

    it("should try to match LP price to UPC virtual price. refund to not be processed", async () => {
      await UP_TOKEN.mint(admin.address, ethers.utils.parseEther("10"))
      const ethAmount = ethers.utils.parseEther("1")

      await darbiContract.setDarbiFunds(ethers.utils.parseEther("6"))
      await darbiContract.withdrawFunds(admin.address)
      await admin.sendTransaction({
        to: darbiContract.address,
        value: ethAmount
      })

      const arbitrageTrx = await darbiContract.arbitrage().then((trx) => trx.wait())

      const pairInterface = IUniswapV2Pair__factory.createInterface()

      const log = arbitrageTrx.logs.find((log) =>
        log.topics.includes(pairInterface.getEventTopic("Swap"))
      )

      const eventData = pairInterface.decodeEventLog("Swap", log!.data)
      const amount1Out = BN(eventData.amount1Out.toHexString())
      const finalBalance = await ethers.provider
        .getBalance(darbiContract.address)
        .then((balance) => BN(balance.toHexString()))

      const PRECISION_THRESHOLD = 1

      expect(amount1Out.plus(finalBalance.negated()).abs().toNumber()).lessThanOrEqual(
        PRECISION_THRESHOLD
      )
    })

    it("should return an amountIn enough for aligning the price of the LP <1% increasing the NativeToken backing UP", async () => {
      await admin.sendTransaction({
        to: UP_CONTROLLER.address,
        value: ethers.utils.parseEther("2") // New balance = 7 ETH / 2 UP
      })
      const virtualPrice = await UP_CONTROLLER["getVirtualPrice()"]().then((res) =>
        BN(res.toHexString())
      )
      await darbiContract.arbitrage()
      const { reserveA, reserveB } = await UNISWAP_HELPER.getReserves(
        contracts["Factory"],
        contracts["WETH"],
        UP_TOKEN.address
      )
      const newPrice = BN(reserveA.toHexString())
        .div(reserveB.toHexString())
        .multipliedBy(ethers.utils.parseEther("1").toHexString())
      const diff = BN(1).minus(newPrice.dividedBy(virtualPrice))
      const diffPercentage = diff.multipliedBy(100).dp(4).abs().toNumber()
      expect(diffPercentage).lessThan(1) // 1% of difference
    })

    it("should try to align LP price to backed value when upc funds were not enough to balance (no refund processed)", async () => {
      await admin.sendTransaction({
        to: UP_CONTROLLER.address,
        value: ethers.utils.parseEther("10") // New balance = 15 ETH / 2 UP
      })

      await UP_CONTROLLER.grantRole(await UP_CONTROLLER.REBALANCER_ROLE(), admin.address)
      await UP_CONTROLLER.borrowNative(ethers.utils.parseEther("14"), admin.address)
      await darbiContract.setDarbiFunds(ethers.utils.parseEther("32"))

      const { reserveA: priorReserveA, reserveB: priorReserveB } = await UNISWAP_HELPER.getReserves(
        contracts["Factory"],
        contracts["WETH"],
        UP_TOKEN.address
      )
      const priorPrice = BN(priorReserveA.toHexString())
        .div(priorReserveB.toHexString())
        .multipliedBy(ethers.utils.parseEther("1").toHexString())

      const virtualPrice = await UP_CONTROLLER["getVirtualPrice()"]().then((res) =>
        BN(res.toHexString())
      )
      await darbiContract.arbitrage()
      const { reserveA, reserveB } = await UNISWAP_HELPER.getReserves(
        contracts["Factory"],
        contracts["WETH"],
        UP_TOKEN.address
      )
      const newPrice = BN(reserveA.toHexString())
        .div(reserveB.toHexString())
        .multipliedBy(ethers.utils.parseEther("1").toHexString())
      expect(newPrice.toNumber()).lessThan(virtualPrice.toNumber())
      expect(newPrice.toNumber()).greaterThan(priorPrice.toNumber())
      expect(
        await ethers.provider.getBalance(UP_CONTROLLER.address).then((bn) => bn.toNumber())
      ).closeTo(0, 10)
    })

    it("should try to align LP price to backed value when upc funds were not enough to balance (refund processed)", async () => {
      await admin.sendTransaction({
        to: UP_CONTROLLER.address,
        value: ethers.utils.parseEther("10") // New balance = 15 ETH / 2 UP
      })

      await UP_CONTROLLER.grantRole(await UP_CONTROLLER.REBALANCER_ROLE(), admin.address)
      await UP_CONTROLLER.borrowNative(ethers.utils.parseEther("14"), admin.address)
      await darbiContract.setDarbiFunds(ethers.utils.parseEther("10"))

      const { reserveA: priorReserveA, reserveB: priorReserveB } = await UNISWAP_HELPER.getReserves(
        contracts["Factory"],
        contracts["WETH"],
        UP_TOKEN.address
      )
      const priorPrice = BN(priorReserveA.toHexString())
        .div(priorReserveB.toHexString())
        .multipliedBy(ethers.utils.parseEther("1").toHexString())

      const virtualPrice = await UP_CONTROLLER["getVirtualPrice()"]().then((res) =>
        BN(res.toHexString())
      )
      await darbiContract.arbitrage()
      const { reserveA, reserveB } = await UNISWAP_HELPER.getReserves(
        contracts["Factory"],
        contracts["WETH"],
        UP_TOKEN.address
      )
      const newPrice = BN(reserveA.toHexString())
        .div(reserveB.toHexString())
        .multipliedBy(ethers.utils.parseEther("1").toHexString())
      expect(newPrice.toNumber()).lessThan(virtualPrice.toNumber())
      expect(newPrice.toNumber()).greaterThan(priorPrice.toNumber())
      expect(await ethers.provider.getBalance(darbiContract.address)).to.be.equal(
        ethers.utils.parseEther("10")
      )
    })
  })

  describe("refund", () => {
    it("Shouldn't refund because balances aren't enough for covering the base balances", async () => {
      const initialBalance = await darbiContract.provider.getBalance(darbiContract.address)
      await darbiContract.setDarbiFunds(ethers.utils.parseEther("6"))
      await expect(darbiContract.refund()).to.not.be.reverted
      const afterBalance = await darbiContract.provider.getBalance(darbiContract.address)
      expect(afterBalance).equal(initialBalance)
    })

    it("Should refund gasRefundAddress and upController when msg.sender is not rebalancer", async () => {
      await darbiContract.setDarbiFunds(ethers.utils.parseEther("4"))
      await darbiContract.revokeRole(await darbiContract.REBALANCER_ROLE(), admin.address)
      const gasRefund = await darbiContract.gasRefund()
      const initialBalance = await darbiContract.provider.getBalance(darbiContract.address)
      expect(initialBalance).equal(ethers.utils.parseEther("5"), "wrong initial balance")
      // const initialGasRefundAddressBalances = await darbiContract.provider.getBalance(admin.address)
      const initialUpControllerBalances = await darbiContract.provider.getBalance(
        UP_CONTROLLER.address
      )
      const refund = await darbiContract.refund()
      // const gasUsage = refund.gasLimit.mul(refund.gasPrice ?? "1")
      // const afterGasRefundAddressBalances = await darbiContract.provider.getBalance(admin.address)
      const afterBalance = await darbiContract.provider.getBalance(darbiContract.address)
      const afterUpControllerBalances = await darbiContract.provider.getBalance(
        UP_CONTROLLER.address
      )
      expect(afterBalance).equal(ethers.utils.parseEther("4"), "wrong darbi after balance")
      // const totalGasRefunds = initialGasRefundAddressBalances.sub(gasUsage).add(gasRefund)
      // expect(totalGasRefunds).equal(afterGasRefundAddressBalances, "wrong gas refund balance")
      expect(
        initialUpControllerBalances.add(
          initialBalance.sub(gasRefund).sub(ethers.utils.parseEther("4"))
        )
      ).equal(afterUpControllerBalances, "wrong up controller balance")
    })

    // it("Should refund gasRefundAddress and upController when msg.sender is rebalancer", async () => {
    //   await darbiContract.setDarbiFunds(ethers.utils.parseEther("4"))
    //   const gasRefund = await darbiContract.gasRefund()
    //   const initialBalance = await darbiContract.provider.getBalance(darbiContract.address)
    //   expect(initialBalance).equal(ethers.utils.parseEther("5"), "wrong initial balance")
    //   // const initialGasRefundAddressBalances = await darbiContract.provider.getBalance(admin.address)
    //   const initialUpControllerBalances = await darbiContract.provider.getBalance(
    //     UP_CONTROLLER.address
    //   )
    //   await darbiContract.refund()
    //   // const gasUsage = refund.gasLimit.mul(refund.gasPrice ?? "1")
    //   // const afterGasRefundAddressBalances = await darbiContract.provider.getBalance(admin.address)
    //   const afterBalance = await darbiContract.provider.getBalance(darbiContract.address)
    //   const afterUpControllerBalances = await darbiContract.provider.getBalance(
    //     UP_CONTROLLER.address
    //   )
    //   expect(afterBalance).equal(initialBalance.sub(gasRefund), "wrong darbi after balance")
    //   // const totalGasRefunds = initialGasRefundAddressBalances.sub(gasUsage).add(gasRefund)
    //   // expect(totalGasRefunds).equal(afterGasRefundAddressBalances, "wrong gas refund balance")
    //   expect(initialUpControllerBalances).equal(
    //     afterUpControllerBalances,
    //     "up controller balance shouldn't change"
    //   )
    // })
  })
})
