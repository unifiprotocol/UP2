import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { assert, expect } from "chai"
import { ethers } from "hardhat"
import {
  Darbi,
  IUnifiPair,
  IUniswapV2Router02,
  Rebalancer,
  UniswapHelper,
  UP,
  UPController,
  UPMintDarbi
} from "../typechain-types"
import contracts from "./Contracts"
import { getUniswapRouter } from "./Helper"

const MEANINGLESS_AMOUNT = "10000"

describe("Rebalancer", function () {
  let UP_TOKEN: UP
  let UP_CONTROLLER: UPController
  let UP_MINT_DARBI: UPMintDarbi
  let DARBI: Darbi
  let uniswapHelper: UniswapHelper
  let rebalancer: Rebalancer
  let unpermissionedRebalancer: Rebalancer

  beforeEach(async () => {
    const [, unpermissionedAccount] = await ethers.getSigners()
    uniswapHelper = await ethers.getContractFactory("UniswapHelper").then((cf) => cf.deploy())
    rebalancer = await ethers
      .getContractFactory("Rebalancer", {
        libraries: {
          UniswapHelper: uniswapHelper.address
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

  describe("getLiquidityPoolBalance", () => {
    let addr1: SignerWithAddress
    let router: IUniswapV2Router02
    let liquidityPool: IUnifiPair

    beforeEach(async () => {
      const [a1] = await ethers.getSigners()
      addr1 = a1

      router = await getUniswapRouter(contracts["Router"])

      UP_TOKEN = await ethers
        .getContractFactory("UP")
        .then((factory) => factory.deploy())
        .then((instance) => instance.deployed())

      await UP_TOKEN.grantRole(await UP_TOKEN.MINT_ROLE(), addr1.address)
      await UP_TOKEN.mint(addr1.address, ethers.utils.parseEther("2"))
      await UP_TOKEN.approve(router.address, ethers.utils.parseEther("666"))

      await router.addLiquidityETH(
        UP_TOKEN.address,
        ethers.utils.parseEther("2"),
        0,
        0,
        addr1.address,
        Date.now() + 150,
        { value: ethers.utils.parseEther("5") }
      )

      const factory = await ethers.getContractAt("IUniswapV2Factory", contracts["Factory"])
      const pairAddress = await factory.getPair(UP_TOKEN.address, contracts["WETH"])
      liquidityPool = await ethers.getContractAt("IUnifiPair", pairAddress)

      UP_CONTROLLER = await ethers
        .getContractFactory("UPController")
        .then((cf) => cf.deploy(UP_TOKEN.address))

      await addr1.sendTransaction({
        to: UP_CONTROLLER.address,
        value: ethers.utils.parseEther("5")
      })
      await UP_TOKEN.grantRole(await UP_TOKEN.MINT_ROLE(), addr1.address)
      await UP_TOKEN.mint(addr1.address, ethers.utils.parseEther("2"))

      UP_MINT_DARBI = await ethers
        .getContractFactory("UPMintDarbi")
        .then((factory) => factory.deploy(UP_TOKEN.address, UP_CONTROLLER.address))
        .then((instance) => instance.deployed())

      await UP_TOKEN.grantRole(await UP_TOKEN.MINT_ROLE(), UP_MINT_DARBI.address)

      DARBI = await ethers
        .getContractFactory("Darbi", {
          libraries: {
            UniswapHelper: uniswapHelper.address
          }
        })
        .then((factory) =>
          factory.deploy(
            contracts["Factory"],
            contracts["Router"],
            contracts["WETH"],
            addr1.address,
            UP_CONTROLLER.address,
            UP_MINT_DARBI.address,
            MEANINGLESS_AMOUNT
          )
        )

      await addr1.sendTransaction({
        to: DARBI.address,
        value: ethers.utils.parseEther("5")
      })

      rebalancer = await ethers
        .getContractFactory("Rebalancer", {
          libraries: {
            UniswapHelper: uniswapHelper.address
          }
        })
        .then((cf) =>
          cf.deploy(
            contracts["WETH"],
            UP_TOKEN.address,
            UP_CONTROLLER.address,
            ethers.constants.AddressZero,
            contracts["Router"],
            contracts["Factory"],
            pairAddress,
            DARBI.address
          )
        )
    })

    it("Should return the correct amount of reserves for LP holder", async () => {
      await liquidityPool.transfer(rebalancer.address, await liquidityPool.balanceOf(addr1.address))
      const reserves = await uniswapHelper.getReserves(
        contracts["Factory"],
        UP_TOKEN.address,
        contracts["WETH"]
      )
      const [reserves0, reserves1] = await rebalancer.getLiquidityPoolBalance(
        reserves.reserveA,
        reserves.reserveB
      )
      // We loose precission because the operation in the SC
      expect(reserves0).closeTo(ethers.utils.parseEther("2"), 10000)
      expect(reserves1).closeTo(ethers.utils.parseEther("5"), 10000)
    })

    it("Should return (0,0) because no LP in Rebalance", async () => {
      const reserves = await uniswapHelper.getReserves(
        contracts["Factory"],
        UP_TOKEN.address,
        contracts["WETH"]
      )
      const [reserves0, reserves1] = await rebalancer.getLiquidityPoolBalance(
        reserves.reserveA,
        reserves.reserveB
      )
      expect(reserves0).equals(0)
      expect(reserves1).equals(0)
    })
  })

  describe.only("rebalance", () => {
    describe("without strategy", () => {
      let addr1: SignerWithAddress
      let router: IUniswapV2Router02
      let liquidityPool: IUnifiPair

      beforeEach(async () => {
        const [a1] = await ethers.getSigners()
        addr1 = a1

        router = await getUniswapRouter(contracts["Router"])

        UP_TOKEN = await ethers
          .getContractFactory("UP")
          .then((factory) => factory.deploy())
          .then((instance) => instance.deployed())

        await UP_TOKEN.grantRole(await UP_TOKEN.MINT_ROLE(), addr1.address)
        await UP_TOKEN.mint(addr1.address, ethers.utils.parseEther("4"))
        await UP_TOKEN.approve(router.address, ethers.utils.parseEther("666"))

        await router.addLiquidityETH(
          UP_TOKEN.address,
          ethers.utils.parseEther("2"),
          0,
          0,
          addr1.address,
          Date.now() + 150,
          { value: ethers.utils.parseEther("5") }
        )

        const factory = await ethers.getContractAt("IUniswapV2Factory", contracts["Factory"])
        const pairAddress = await factory.getPair(UP_TOKEN.address, contracts["WETH"])
        liquidityPool = await ethers.getContractAt("IUnifiPair", pairAddress)

        UP_CONTROLLER = await ethers
          .getContractFactory("UPController")
          .then((cf) => cf.deploy(UP_TOKEN.address))

        await addr1.sendTransaction({
          to: UP_CONTROLLER.address,
          value: ethers.utils.parseEther("10")
        })
        await UP_TOKEN.grantRole(await UP_TOKEN.MINT_ROLE(), addr1.address)

        UP_MINT_DARBI = await ethers
          .getContractFactory("UPMintDarbi")
          .then((factory) => factory.deploy(UP_TOKEN.address, UP_CONTROLLER.address))
          .then((instance) => instance.deployed())

        await UP_TOKEN.grantRole(await UP_TOKEN.MINT_ROLE(), UP_MINT_DARBI.address)

        DARBI = await ethers
          .getContractFactory("Darbi", {
            libraries: {
              UniswapHelper: uniswapHelper.address
            }
          })
          .then((factory) =>
            factory.deploy(
              contracts["Factory"],
              contracts["Router"],
              contracts["WETH"],
              addr1.address,
              UP_CONTROLLER.address,
              UP_MINT_DARBI.address,
              MEANINGLESS_AMOUNT
            )
          )

        await addr1.sendTransaction({
          to: DARBI.address,
          value: ethers.utils.parseEther("10")
        })

        rebalancer = await ethers
          .getContractFactory("Rebalancer", {
            libraries: {
              UniswapHelper: uniswapHelper.address
            }
          })
          .then((cf) =>
            cf.deploy(
              contracts["WETH"],
              UP_TOKEN.address,
              UP_CONTROLLER.address,
              ethers.constants.AddressZero,
              contracts["Router"],
              contracts["Factory"],
              pairAddress,
              DARBI.address
            )
          )

        await rebalancer.grantRole(await rebalancer.REBALANCE_ROLE(), addr1.address)
        await DARBI.grantRole(await DARBI.REBALANCER_ROLE(), rebalancer.address)
        await UP_CONTROLLER.grantRole(await UP_CONTROLLER.REBALANCER_ROLE(), rebalancer.address)
        await UP_CONTROLLER.grantRole(await UP_CONTROLLER.REDEEMER_ROLE(), rebalancer.address)
        await UP_CONTROLLER.grantRole(await UP_CONTROLLER.REDEEMER_ROLE(), DARBI.address)
        await UP_MINT_DARBI.grantDarbiRole(DARBI.address)
        await UP_TOKEN.grantRole(await UP_TOKEN.MINT_ROLE(), UP_CONTROLLER.address)
      })

      it("Should add liquidity to the LP when there is no LP tokens yet", async () => {
        const initialLP = await liquidityPool.balanceOf(rebalancer.address)
        assert(initialLP.eq(0))
        await rebalancer.rebalance()
        const finalLP = await liquidityPool.balanceOf(rebalancer.address)
        assert(finalLP.gt(0), "LP balance cannot be 0")
      })

      it("Shouldn't rebalance again because the LP is already balanced", async () => {
        await rebalancer.rebalance()
        await expect(rebalancer.rebalance()).revertedWith("ALREADY_REBALANCED")
      })

      it("Should rebalance the LP because the UPController redeem value went down", async () => {
        await rebalancer.rebalance()
        const initialNativeBorrow = await UP_CONTROLLER.nativeBorrowed()
        const initialUpBorrow = await UP_CONTROLLER.upBorrowed()
        const initialLp = await liquidityPool.balanceOf(rebalancer.address)

        await UP_TOKEN.mint(addr1.address, ethers.utils.parseEther("0.05"))
        // NEW VIRTUAL PRICE = 10/4.05 = ~2.469 | PREVIOUS = 10/4 = 2.5 = ~1.01% deviation
        await rebalancer.rebalance()

        const finalNativeBorrow = await UP_CONTROLLER.nativeBorrowed()
        const finalUpBorrow = await UP_CONTROLLER.upBorrowed()
        const finalLp = await liquidityPool.balanceOf(rebalancer.address)

        assert(initialNativeBorrow.lt(finalNativeBorrow), "BORROWED ETH AMOUNTS ARE NOT LESSER")
        assert(initialUpBorrow.lt(finalUpBorrow), "BORROWED UP AMOUNTS ARE NOT LESSER")
        assert(initialLp.lt(finalLp), "LP POSITION SHOULD DECREASE")
      })

      it("Should rebalance the LP because the UPController redeem value went up", async () => {
        await rebalancer.rebalance()
        const initialNativeBorrow = await UP_CONTROLLER.nativeBorrowed()
        const initialUpBorrow = await UP_CONTROLLER.upBorrowed()
        const initialLp = await liquidityPool.balanceOf(rebalancer.address)

        await UP_TOKEN.burn(ethers.utils.parseEther("0.05"))
        // NEW VIRTUAL PRICE = 10/3.95 = ~2.531 | PREVIOUS = 10/4 = 2.5 = ~1.01% deviation
        await rebalancer.rebalance()

        const finalNativeBorrow = await UP_CONTROLLER.nativeBorrowed()
        const finalUpBorrow = await UP_CONTROLLER.upBorrowed()
        const finalLp = await liquidityPool.balanceOf(rebalancer.address)

        assert(initialNativeBorrow.gt(finalNativeBorrow), "BORROWED ETH AMOUNTS ARE NOT GREATER")
        assert(initialUpBorrow.gt(finalUpBorrow), "BORROWED UP AMOUNTS ARE NOT GREATER")
        assert(initialLp.gt(finalLp), "LP POSITION SHOULD GROW")
      })
    })
  })
})
