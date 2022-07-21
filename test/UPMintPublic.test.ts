import { ethers, network } from "hardhat"
import { expect } from "chai"
import { UP, UPController, UPMintPublic } from "../typechain-types"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { BigNumber } from "ethers"

describe("UPMintPublic", () => {
  let upToken: UP
  let upController: UPController
  let upMintPublic: UPMintPublic
  let addr1: SignerWithAddress

  beforeEach(async () => {
    const [a1] = await ethers.getSigners()
    addr1 = a1
    upToken = await ethers
      .getContractFactory("UP")
      .then((factory) => factory.deploy())
      .then((instance) => instance.deployed())
    upController = await ethers
      .getContractFactory("UPController")
      .then((factory) => factory.deploy(upToken.address, addr1.address))
      .then((instance) => instance.deployed())
    upMintPublic = await ethers
      .getContractFactory("UPMintPublic")
      .then((factory) => factory.deploy(upToken.address, upController.address, 5, addr1.address))
      .then((instance) => instance.deployed())
    await upToken.grantRole(await upToken.MINT_ROLE(), addr1.address)
    await upToken.grantRole(await upToken.MINT_ROLE(), upMintPublic.address)
  })

  it('Should set a new "mintRate"', async () => {
    await upMintPublic.setMintRate(100)
    expect(await upMintPublic.mintRate()).equal(100)
  })

  it('Shouldnt set a new "mintRate" because not enough permissions', async () => {
    const [, addr2] = await ethers.getSigners()
    const addr2UpController = upMintPublic.connect(addr2)
    await expect(addr2UpController.setMintRate(100)).revertedWith(
      "Ownable: caller is not the owner"
    )
  })

  it('Should revert "setMintRate" because value is out of threshold #0', async () => {
    await expect(upMintPublic.setMintRate(101)).revertedWith("MINT_RATE_GT_100")
  })

  it('Should revert "setMintRate" because value is out of threshold #1', async () => {
    await expect(upMintPublic.setMintRate(0)).revertedWith("MINT_RATE_EQ_0")
  })

  describe("MintUP", () => {
    let addr2: SignerWithAddress
    let addr2UpMintPublic: UPMintPublic

    beforeEach(async () => {
      const [, a2] = await ethers.getSigners()
      addr2 = a2
      addr2UpMintPublic = upMintPublic.connect(a2)
    })

    function getExpectedMint(virtualPrice: BigNumber, sendValue: BigNumber): BigNumber {
      const discountedAmount = sendValue.sub(
        sendValue.mul(ethers.BigNumber.from("5").mul(100)).div(10_000)
      )
      const expectedMint = discountedAmount.mul(ethers.utils.parseEther("1")).div(virtualPrice)
      return expectedMint
    }

    it("Should mint UP at premium rates #0", async () => {
      await addr1.sendTransaction({
        to: upController.address,
        value: ethers.utils.parseEther("5")
      })
      await upToken.mint(upController.address, ethers.utils.parseEther("2"))
      const sendValue = ethers.utils.parseEther("100")
      const virtualPrice = ethers.utils.parseEther("2.5")
      const expectedMint = getExpectedMint(virtualPrice, sendValue)
      await addr2UpMintPublic.mintUP(addr2.address, { value: sendValue })
      expect(await upToken.balanceOf(addr2.address)).equal(expectedMint)
      expect(await upController.provider.getBalance(upController.address)).equal(
        ethers.utils.parseEther("5").add(sendValue)
      )
    })

    it("Should mint UP at premium rates #1", async () => {
      await addr1.sendTransaction({
        to: upController.address,
        value: ethers.utils.parseEther("5")
      })
      await upToken.mint(upController.address, ethers.utils.parseEther("2"))
      const sendValue = ethers.utils.parseEther("5")
      const virtualPrice = ethers.utils.parseEther("2.5")
      const expectedMint = getExpectedMint(virtualPrice, sendValue)
      await addr2UpMintPublic.mintUP(addr2.address, { value: sendValue })
      expect(await upToken.balanceOf(addr2.address)).equal(expectedMint)
      expect(await upController.provider.getBalance(upController.address)).equal(
        ethers.utils.parseEther("5").add(sendValue)
      )
    })

    it("Should mint UP at premium rates #2", async () => {
      await addr1.sendTransaction({
        to: upController.address,
        value: ethers.utils.parseEther("5")
      })
      await upToken.mint(upMintPublic.address, ethers.utils.parseEther("2"))
      const sendValue = ethers.utils.parseEther("31")
      const virtualPrice = ethers.utils.parseEther("2.5")
      const expectedMint = getExpectedMint(virtualPrice, sendValue)
      await addr2UpMintPublic.mintUP(addr2.address, { value: sendValue })
      expect(await upToken.balanceOf(addr2.address)).equal(expectedMint)
      expect(await upController.provider.getBalance(upController.address)).equal(
        ethers.utils.parseEther("5").add(sendValue)
      )
    })

    it("Should mint UP at premium rates #3", async () => {
      await addr1.sendTransaction({
        to: upController.address,
        value: ethers.utils.parseEther("5")
      })
      await upToken.mint(upMintPublic.address, ethers.utils.parseEther("2"))
      const sendValue = ethers.utils.parseEther("1233")
      const virtualPrice = ethers.utils.parseEther("2.5")
      const expectedMint = getExpectedMint(virtualPrice, sendValue)
      await addr2UpMintPublic.mintUP(addr2.address, { value: sendValue })
      expect(await upToken.balanceOf(addr2.address)).equal(expectedMint)
      expect(await upController.provider.getBalance(upController.address)).equal(
        ethers.utils.parseEther("5").add(sendValue)
      )
    })

    it("Should mint UP at premium rates #4", async () => {
      await addr1.sendTransaction({
        to: upController.address,
        value: ethers.utils.parseEther("5")
      })
      await upToken.mint(upMintPublic.address, ethers.utils.parseEther("2"))
      const sendValue = ethers.utils.parseEther("999.1")
      const virtualPrice = ethers.utils.parseEther("2.5")
      const expectedMint = getExpectedMint(virtualPrice, sendValue)
      await addr2UpMintPublic.mintUP(addr2.address, { value: sendValue })
      expect(await upToken.balanceOf(addr2.address)).equal(expectedMint)
      expect(await upController.provider.getBalance(upController.address)).equal(
        ethers.utils.parseEther("5").add(sendValue)
      )
    })

    it("Should mint UP at premium rates #5", async () => {
      await network.provider.send("hardhat_setBalance", [
        addr2.address,
        ethers.utils.parseEther("99900").toHexString()
      ])
      await addr1.sendTransaction({
        to: upController.address,
        value: ethers.utils.parseEther("5")
      })
      await upToken.mint(upMintPublic.address, ethers.utils.parseEther("2"))
      const sendValue = ethers.utils.parseEther("91132.42")
      const virtualPrice = ethers.utils.parseEther("2.5")
      const expectedMint = getExpectedMint(virtualPrice, sendValue)
      await addr2UpMintPublic.mintUP(addr2.address, { value: sendValue })
      expect(await upToken.balanceOf(addr2.address)).equal(expectedMint)
      expect(await upController.provider.getBalance(upController.address)).equal(
        ethers.utils.parseEther("5").add(sendValue)
      )
    })

    it("Should mint UP at premium rates #6", async () => {
      await addr1.sendTransaction({
        to: upController.address,
        value: ethers.utils.parseEther("5")
      })
      await upToken.mint(upMintPublic.address, ethers.utils.parseEther("4"))
      const sendValue = ethers.utils.parseEther("999")
      const virtualPrice = ethers.utils.parseEther("1.25")
      const expectedMint = getExpectedMint(virtualPrice, sendValue)
      await addr2UpMintPublic.mintUP(addr2.address, { value: sendValue })
      expect(await upToken.balanceOf(addr2.address)).equal(expectedMint)
      expect(await upController.provider.getBalance(upController.address)).equal(
        ethers.utils.parseEther("5").add(sendValue)
      )
    })

    it("Should fail minting UP because payable value is zero", async () => {
      await expect(upMintPublic.mintUP(addr1.address, { value: 0 })).revertedWith(
        "INVALID_PAYABLE_AMOUNT"
      )
    })

    it("Should mint zero UP because virtual price is zero and throw UP_PRICE_0", async () => {
      await expect(
        upMintPublic.mintUP(addr1.address, { value: ethers.utils.parseEther("100") })
      ).revertedWith("UP_PRICE_0")
      expect(await upToken.balanceOf(addr1.address)).equal(0)
    })

    it("Shouldn't mint up because contract is paused", async () => {
      await upMintPublic.pause()
      await expect(
        upMintPublic.mintUP(addr1.address, { value: ethers.utils.parseEther("100") })
      ).revertedWith("Pausable: pause")
    })

    it("Should mint UP after pause and unpause", async () => {
      await addr1.sendTransaction({
        to: upController.address,
        value: ethers.utils.parseEther("5")
      })
      await upToken.mint(upController.address, ethers.utils.parseEther("2"))
      await upMintPublic.pause()
      await expect(
        addr2UpMintPublic.mintUP(addr2.address, { value: ethers.utils.parseEther("100") })
      ).revertedWith("Pausable: pause")
      await upMintPublic.unpause()
      const sendValue = ethers.utils.parseEther("100")
      const virtualPrice = ethers.utils.parseEther("2.5")
      const expectedMint = getExpectedMint(virtualPrice, sendValue)
      await addr2UpMintPublic.mintUP(addr2.address, { value: sendValue })
      expect(await upToken.balanceOf(addr2.address)).equal(expectedMint)
      expect(await upController.provider.getBalance(upController.address)).equal(
        ethers.utils.parseEther("5").add(sendValue)
      )
    })
  })
})
