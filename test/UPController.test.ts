import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { BN } from "@unifiprotocol/utils"
import { expect } from "chai"
import { assert } from "console"
import { BigNumber } from "ethers"
import { ethers } from "hardhat"
import { UP, UPController } from "../typechain-types"

describe("UPController", function () {
  let upToken: UP
  let upController: UPController
  let addr1: SignerWithAddress

  beforeEach(async () => {
    const [a1] = await ethers.getSigners()
    addr1 = a1
    upToken = await ethers
      .getContractFactory("UP")
      .then((factory) => factory.deploy())
      .then((instance) => instance.deployed())
    await upToken.grantRole(await upToken.MINT_ROLE(), addr1.address)
    upController = await ethers
      .getContractFactory("UPController")
      .then((factory) => factory.deploy(upToken.address, addr1.address))
      .then((instance) => instance.deployed())
    await upToken.grantRole(await upToken.MINT_ROLE(), upController.address)
    await upController.grantRole(await upController.REBALANCER_ROLE(), addr1.address)
  })

  it("Should assert contract basic info", async () => {
    expect(await upController.UP_TOKEN()).equal(upToken.address)
    expect(await upController.nativeBorrowed()).equal(0)
    expect(await upController.upBorrowed()).equal(0)
    expect(await upController.getNativeBalance()).equal(0)
    expect(await upController["getVirtualPrice()"]()).equal(0)
  })

  it("Should change native balance after send funds", async () => {
    await addr1.sendTransaction({
      to: upController.address,
      value: ethers.utils.parseEther("1")
    })
    expect(await upController.getNativeBalance()).equal(ethers.utils.parseEther("1"))
  })

  it("Should change virtualPrice after minting and depositing ETH+UP tokens", async () => {
    await addr1.sendTransaction({
      to: upController.address,
      value: ethers.utils.parseEther("5")
    })
    expect(await upController.getNativeBalance()).equal(ethers.utils.parseEther("5"))
    await upToken.mint(upController.address, ethers.utils.parseEther("2"))
    expect(await upController.actualTotalSupply()).equal(ethers.utils.parseEther("2"))
    expect(await upController["getVirtualPrice()"]()).equal(ethers.utils.parseEther("2.5"))
  })

  it("Should fail calling mintUP because is not UP_TOKEN the caller", async () => {
    await expect(upController.mintUP(addr1.address)).revertedWith("NON_UP_CONTRACT")
  })

  describe("Borrow", () => {
    describe("borrowNative", () => {
      it("Should borrow native funds and update nativeBorrowed", async () => {
        await addr1.sendTransaction({
          to: upController.address,
          value: ethers.utils.parseEther("5")
        })
        await expect(upController.borrowNative(ethers.utils.parseEther("3"), addr1.address))
          .to.emit(upController, "BorrowNative")
          .withArgs(addr1.address, ethers.utils.parseEther("3"), ethers.utils.parseEther("3"))
        expect(await upController.nativeBorrowed()).equal(ethers.utils.parseEther("3"))
        expect(await upController.getNativeBalance()).equal(ethers.utils.parseEther("5"))
        expect(await upController.provider.getBalance(upController.address)).equal(
          ethers.utils.parseEther("2")
        )
      })

      it("Should fail borrowing native tokens because there is not enough balances", async () => {
        await addr1.sendTransaction({
          to: upController.address,
          value: ethers.utils.parseEther("4")
        })
        await expect(
          upController.borrowNative(ethers.utils.parseEther("6"), addr1.address)
        ).revertedWith("NOT_ENOUGH_BALANCE")
      })

      it("Should fail borrowing native tokens because is not owner", async () => {
        const [, addr2] = await ethers.getSigners()
        const addr2UpController = upController.connect(addr2)
        await expect(
          addr2UpController.borrowNative(ethers.utils.parseEther("6"), addr1.address)
        ).revertedWith("ONLY_REBALANCER")
      })
    })

    describe("borrowUP", () => {
      it("Should borrow UP funds and update upBorrowed", async () => {
        await expect(upController.borrowUP(ethers.utils.parseEther("3"), addr1.address))
          .to.emit(upController, "SyntheticMint")
          .withArgs(addr1.address, ethers.utils.parseEther("3"), ethers.utils.parseEther("3"))
        expect(await upController.upBorrowed()).equal(ethers.utils.parseEther("3"))
        expect(await upController.actualTotalSupply()).equal(ethers.utils.parseEther("0"))
        expect(await upToken.totalSupply()).equal(ethers.utils.parseEther("3"))
        expect(await upToken.balanceOf(addr1.address)).equal(ethers.utils.parseEther("3"))
      })

      it("Should fail borrowing UP tokens because is not owner", async () => {
        const [, addr2] = await ethers.getSigners()
        const addr2UpController = upController.connect(addr2)
        await expect(
          addr2UpController.borrowUP(ethers.utils.parseEther("6"), addr1.address)
        ).revertedWith("ONLY_REBALANCER")
      })
    })

    describe("repay", () => {
      it("Should repay borrowed UP and restore the borrowed count to zero", async () => {
        await upController.borrowUP(ethers.utils.parseEther("3"), addr1.address)
        await upToken.approve(upController.address, ethers.utils.parseEther("3"))
        await expect(upController.repay(ethers.utils.parseEther("3")))
          .to.emit(upController, "Repay")
          .withArgs(0, ethers.utils.parseEther("3"))
        expect(await upController.upBorrowed()).equal(ethers.utils.parseEther("0"))
      })

      it("Should repay borrowed native and restore the borrowed count to zero", async () => {
        await addr1.sendTransaction({
          to: upController.address,
          value: ethers.utils.parseEther("4")
        })
        await upController.borrowNative(ethers.utils.parseEther("4"), addr1.address)
        await expect(upController.repay(0, { value: ethers.utils.parseEther("4") }))
          .to.emit(upController, "Repay")
          .withArgs(ethers.utils.parseEther("4"), 0)
        expect(await upController.nativeBorrowed()).equal(ethers.utils.parseEther("0"))
      })

      it("Should repay borrowed native and borrowed UP and restore the borrowed count to zero", async () => {
        await addr1.sendTransaction({
          to: upController.address,
          value: ethers.utils.parseEther("4")
        })
        await upController.borrowNative(ethers.utils.parseEther("4"), addr1.address)
        await upController.borrowUP(ethers.utils.parseEther("3"), addr1.address)
        await upToken.approve(upController.address, ethers.utils.parseEther("3"))
        await expect(
          upController.repay(ethers.utils.parseEther("3"), { value: ethers.utils.parseEther("4") })
        )
          .to.emit(upController, "Repay")
          .withArgs(ethers.utils.parseEther("4"), ethers.utils.parseEther("3"))
        expect(await upController.nativeBorrowed()).equal(ethers.utils.parseEther("0"))
        expect(await upController.upBorrowed()).equal(ethers.utils.parseEther("0"))
      })

      it("Should fail repaying native tokens because amount is higher than the borrowed", async () => {
        await addr1.sendTransaction({
          to: upController.address,
          value: ethers.utils.parseEther("4")
        })
        await upController.borrowNative(ethers.utils.parseEther("4"), addr1.address)
        await expect(upController.repay(0, { value: ethers.utils.parseEther("5") })).revertedWith(
          "NATIVE_AMOUNT_GT_BORROWED"
        )
        expect(await upController.nativeBorrowed()).equal(ethers.utils.parseEther("4"))
      })

      it("Should fail repaying UP tokens because amount is higher than the borrowed", async () => {
        await upController.borrowUP(ethers.utils.parseEther("3"), addr1.address)
        await upToken.approve(upController.address, ethers.utils.parseEther("3"))
        await expect(upController.repay(ethers.utils.parseEther("4"))).revertedWith(
          "UP_AMOUNT_GT_BORROWED"
        )
        expect(await upController.upBorrowed()).equal(ethers.utils.parseEther("3"))
      })

      it("Should fail repaying tokens because is not owner", async () => {
        const [, addr2] = await ethers.getSigners()
        const addr2UpController = upController.connect(addr2)
        await expect(addr2UpController.repay(ethers.utils.parseEther("6"))).revertedWith(
          "ONLY_REBALANCER"
        )
      })
    })

    describe("Redeem", () => {
      let addr2: SignerWithAddress
      let addr2UpController: UPController
      let addr2UpToken: UP

      beforeEach(async () => {
        const [, a2] = await ethers.getSigners()
        addr2 = a2
        await upController.grantRole(await upController.REDEEMER_ROLE(), addr2.address)
        addr2UpController = upController.connect(addr2)
        addr2UpToken = upToken.connect(addr2)
      })

      it("Should redeem UP by native tokens", async () => {
        await addr1.sendTransaction({
          to: upController.address,
          value: ethers.utils.parseEther("5")
        })
        await upToken.mint(upController.address, ethers.utils.parseEther("2"))
        await upToken.mint(addr2.address, ethers.utils.parseEther("2"))
        expect(await upToken.totalSupply()).equal(ethers.utils.parseEther("4"))
        await addr2UpToken.approve(upController.address, ethers.utils.parseEther("2"))
        await expect(addr2UpController.redeem(ethers.utils.parseEther("2")))
          .to.emit(upController, "Redeem")
          .withArgs(ethers.utils.parseEther("2"), ethers.utils.parseEther("2.5"))
        expect(await upToken.totalSupply()).equal(ethers.utils.parseEther("2"))
      })

      it("Should fail because redeem amount is zero", async () => {
        await expect(addr2UpController.redeem(ethers.utils.parseEther("0"))).revertedWith(
          "AMOUNT_EQ_0"
        )
      })

      it("Should fail because not enough UP balance", async () => {
        await addr1.sendTransaction({
          to: upController.address,
          value: ethers.utils.parseEther("5")
        })
        await upToken.mint(upController.address, ethers.utils.parseEther("2"))
        await upToken.mint(addr2.address, ethers.utils.parseEther("2"))
        await addr2UpToken.approve(upController.address, ethers.utils.parseEther("3"))
        await expect(addr2UpController.redeem(ethers.utils.parseEther("3"))).revertedWith(
          "ERC20: burn amount exceeds balance"
        )
      })

      it("Should fail invoker is not REDEEMER_ROLE", async () => {
        await addr1.sendTransaction({
          to: upController.address,
          value: ethers.utils.parseEther("5")
        })
        await upToken.mint(addr2.address, ethers.utils.parseEther("2"))
        await upController.revokeRole(await upController.REDEEMER_ROLE(), addr2.address)
        await expect(upController.redeem(ethers.utils.parseEther("0"))).revertedWith(
          "ONLY_REDEEMER"
        )
      })
    })
  })

  describe("WithdrawFunds", () => {
    it("Should withdraw 1 UP using withdrawFundsERC20", async () => {
      await upToken.mint(upController.address, ethers.constants.WeiPerEther)
      await upController.withdrawFundsERC20(upToken.address)
      expect(await upToken.balanceOf(upController.address)).equal(0)
      expect(await upToken.balanceOf(addr1.address)).equal(ethers.constants.WeiPerEther)
    })

    it("Should withdraw 1 ETH using withdrawFunds", async () => {
      await addr1.sendTransaction({
        to: upController.address,
        value: ethers.constants.WeiPerEther
      })
      const priorAddr1Balance = await ethers.provider.getBalance(addr1.address)
      expect(await upController.provider.getBalance(upController.address)).equal(
        ethers.constants.WeiPerEther
      )
      await upController.withdrawFunds()
      const addr1Balance = await ethers.provider.getBalance(addr1.address)
      expect(await upController.provider.getBalance(upController.address)).equal(0)
      const balanceDiff = addr1Balance.sub(priorAddr1Balance)
      const threshold = ethers.constants.WeiPerEther.div(2)
      assert(
        balanceDiff.gt(threshold),
        `Balance diff (${ethers.utils.formatEther(
          balanceDiff
        )}) should be greater than threshold (${ethers.utils.formatEther(threshold)} ETH)`
      )
    })

    it("Should fail withdrawing 1 UP using withdrawFundsERC20 because is not owner", async () => {
      const [, addr2] = await ethers.getSigners()
      const addr2upController = upController.connect(addr2)
      await upToken.mint(upController.address, ethers.constants.WeiPerEther)
      await expect(addr2upController.withdrawFundsERC20(upToken.address)).revertedWith("ONLY_ADMIN")
      expect(await upToken.balanceOf(upController.address)).equal(ethers.constants.WeiPerEther)
      expect(await upToken.balanceOf(addr2.address)).equal(0)
    })
  })
})
