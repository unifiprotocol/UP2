import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { expect } from "chai"
import { ethers, network } from "hardhat"
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
    await upToken.grantRole(await upToken.CONTROLLER_ROLE(), addr1.address)
    upController = await ethers
      .getContractFactory("UPController")
      .then((factory) => factory.deploy(upToken.address, 5))
      .then((instance) => instance.deployed())
    await upToken.grantRole(await upToken.CONTROLLER_ROLE(), upController.address)
  })

  it("Should assert contract basic info", async () => {
    expect(await upController.UP_TOKEN()).equal(upToken.address)
    expect(await upController.mintRate()).equal(5)
    expect(await upController.nativeBorrowed()).equal(0)
    expect(await upController.upBorrowed()).equal(0)
    expect(await upController.getNativeBalance()).equal(0)
    expect(await upController.getVirtualPrice()).equal(0)
  })

  it('Should set a new "mintRate"', async () => {
    await upController.setMintRate(10)
    expect(await upController.mintRate()).equal(10)
  })

  it('Shouldn\'t set a new "mintRate" because not enough permissions', async () => {
    const [, addr2] = await ethers.getSigners()
    const addr2UpController = upController.connect(addr2)
    await expect(addr2UpController.setMintRate(10)).revertedWith("Ownable: caller is not the owner")
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
    expect(await upController.getVirtualPrice()).equal(ethers.utils.parseEther("2.5"))
  })

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

  it("Should mint up at premium rates #1", async () => {
    await addr1.sendTransaction({
      to: upController.address,
      value: ethers.utils.parseEther("5")
    })
    await upToken.mint(upController.address, ethers.utils.parseEther("2"))
    await upController.mintUP({ value: ethers.utils.parseEther("100") })
    expect(await upToken.balanceOf(addr1.address)).equal(ethers.utils.parseEther("237.5"))
  })

  it("Should mint up at premium rates #2", async () => {
    await addr1.sendTransaction({
      to: upController.address,
      value: ethers.utils.parseEther("5")
    })
    await upToken.mint(upController.address, ethers.utils.parseEther("2"))
    await upController.mintUP({ value: ethers.utils.parseEther("31") })
    expect(await upToken.balanceOf(addr1.address)).equal(ethers.utils.parseEther("73.625"))
  })

  it("Should mint up at premium rates #3", async () => {
    await addr1.sendTransaction({
      to: upController.address,
      value: ethers.utils.parseEther("5")
    })
    await upToken.mint(upController.address, ethers.utils.parseEther("2"))
    await upController.mintUP({ value: ethers.utils.parseEther("1233") })
    expect(await upToken.balanceOf(addr1.address)).equal(ethers.utils.parseEther("2928.375"))
  })

  it("Should mint up at premium rates #4", async () => {
    await addr1.sendTransaction({
      to: upController.address,
      value: ethers.utils.parseEther("5")
    })
    await upToken.mint(upController.address, ethers.utils.parseEther("2"))
    await upController.mintUP({ value: ethers.utils.parseEther("999.1") })
    expect(await upToken.balanceOf(addr1.address)).equal(ethers.utils.parseEther("2372.8625"))
  })

  it("Should mint up at premium rates #5", async () => {
    await network.provider.send("hardhat_setBalance", [
      addr1.address,
      ethers.utils.parseEther("99900").toHexString()
    ])
    await addr1.sendTransaction({
      to: upController.address,
      value: ethers.utils.parseEther("5")
    })
    await upToken.mint(upController.address, ethers.utils.parseEther("2"))
    await upController.mintUP({ value: ethers.utils.parseEther("91132.42") })
    expect(await upToken.balanceOf(addr1.address)).equal(ethers.utils.parseEther("216439.4975"))
  })

  it("Shouldn't mint up because contract is paused", async () => {
    await upController.pause()
    await expect(upController.mintUP({ value: ethers.utils.parseEther("100") })).revertedWith(
      "Pausable: pause"
    )
  })
})
