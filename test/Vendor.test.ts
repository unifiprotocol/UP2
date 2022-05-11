import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { expect } from "chai"
import { ethers } from "hardhat"
import { UP, Vendor } from "../typechain-types"

describe("Vendor", function () {
  let upToken1: UP
  let upToken2: UP
  let vendor: Vendor
  let addr1: SignerWithAddress

  beforeEach(async () => {
    const [a1] = await ethers.getSigners()
    addr1 = a1

    upToken1 = await ethers
      .getContractFactory("UP")
      .then((factory) => factory.deploy())
      .then((instance) => instance.deployed())
    upToken2 = await ethers
      .getContractFactory("UP")
      .then((factory) => factory.deploy())
      .then((instance) => instance.deployed())
    vendor = await ethers
      .getContractFactory("Vendor")
      .then((factory) => factory.deploy(upToken1.address, upToken2.address))
      .then((instance) => instance.deployed())

    const controllerRoleNS1 = await upToken1.CONTROLLER_ROLE()
    const controllerRoleNS2 = await upToken2.CONTROLLER_ROLE()
    await upToken1.grantRole(controllerRoleNS1, addr1.address)
    await upToken2.grantRole(controllerRoleNS2, addr1.address)
  })

  it("Should assert contract basic info", async () => {
    await upToken2.mint(vendor.address, ethers.constants.WeiPerEther)
    expect(await vendor.OLD_UP()).equal(upToken1.address)
    expect(await vendor.UP()).equal(upToken2.address)
    expect(await vendor.balance()).equal(ethers.constants.WeiPerEther)
    expect(await vendor.owner()).equal(addr1.address)
  })

  it("Should swap 1 OLD UP by 1 UP", async () => {
    await upToken1.mint(addr1.address, ethers.constants.WeiPerEther)
    await upToken2.mint(vendor.address, ethers.constants.WeiPerEther)

    expect(await upToken1.balanceOf(vendor.address)).equal(0)
    expect(await upToken2.balanceOf(vendor.address)).equal(ethers.constants.WeiPerEther)

    await upToken1.approve(vendor.address, ethers.constants.WeiPerEther)

    await expect(vendor.swap(ethers.constants.WeiPerEther))
      .to.emit(vendor, "Swap")
      .withArgs(addr1.address, ethers.constants.WeiPerEther)
    expect(await upToken1.balanceOf(vendor.address)).equal(ethers.constants.WeiPerEther)
    expect(await upToken2.balanceOf(vendor.address)).equal(0)
  })

  it("Swap should fail because insufficent balances on the contract", async () => {
    await upToken1.mint(addr1.address, ethers.constants.WeiPerEther)
    await upToken2.mint(vendor.address, ethers.constants.WeiPerEther.div(2))
    await upToken1.approve(vendor.address, ethers.constants.WeiPerEther)
    await expect(vendor.swap(ethers.constants.WeiPerEther)).revertedWith(
      "ERC20: transfer amount exceeds balance"
    )
    expect(await upToken1.balanceOf(vendor.address)).equal(0)
    expect(await upToken2.balanceOf(vendor.address)).equal(ethers.constants.WeiPerEther.div(2))
  })

  it("Swap should fail because the user has insufficent funds", async () => {
    await upToken2.mint(vendor.address, ethers.constants.WeiPerEther)
    await upToken1.approve(vendor.address, ethers.constants.WeiPerEther)
    await expect(vendor.swap(ethers.constants.WeiPerEther)).revertedWith(
      "ERC20: transfer amount exceeds balance"
    )
    expect(await upToken1.balanceOf(vendor.address)).equal(0)
    expect(await upToken2.balanceOf(vendor.address)).equal(ethers.constants.WeiPerEther)
  })

  it("Should fail because contract is paused", async () => {
    await upToken1.mint(addr1.address, ethers.constants.WeiPerEther)
    await upToken2.mint(vendor.address, ethers.constants.WeiPerEther)

    await upToken1.approve(vendor.address, ethers.constants.WeiPerEther)
    await vendor.pause()

    await expect(vendor.swap(ethers.constants.WeiPerEther)).revertedWith("Pausable: paused")
    expect(await upToken1.balanceOf(vendor.address)).equal(0)
    expect(await upToken2.balanceOf(vendor.address)).equal(ethers.constants.WeiPerEther)
  })

  it("Should swap 1 OLD UP by 1 UP after paused and unpaused", async () => {
    await upToken1.mint(addr1.address, ethers.constants.WeiPerEther)
    await upToken2.mint(vendor.address, ethers.constants.WeiPerEther)
    await upToken1.approve(vendor.address, ethers.constants.WeiPerEther)
    await vendor.pause()
    await expect(vendor.swap(ethers.constants.WeiPerEther)).revertedWith("Pausable: paused")
    await vendor.unpause()
    await expect(vendor.swap(ethers.constants.WeiPerEther))
      .to.emit(vendor, "Swap")
      .withArgs(addr1.address, ethers.constants.WeiPerEther)
    expect(await upToken1.balanceOf(vendor.address)).equal(ethers.constants.WeiPerEther)
    expect(await upToken2.balanceOf(vendor.address)).equal(0)
  })

  it("Should withdraw 1 UP using withdrawFundsERC20", async () => {
    await upToken2.mint(vendor.address, ethers.constants.WeiPerEther)
    await vendor.withdrawFundsERC20(addr1.address, upToken2.address)
    expect(await upToken2.balanceOf(vendor.address)).equal(0)
    expect(await upToken2.balanceOf(addr1.address)).equal(ethers.constants.WeiPerEther)
  })

  it("Should fail withdrawing 1 UP using withdrawFundsERC20 because is not owner", async () => {
    const [, addr2] = await ethers.getSigners()
    const addr2Vendor = vendor.connect(addr2)
    await upToken2.mint(vendor.address, ethers.constants.WeiPerEther)
    await expect(addr2Vendor.withdrawFundsERC20(addr2.address, upToken2.address)).revertedWith(
      "Ownable: caller is not the owner"
    )
    expect(await upToken2.balanceOf(vendor.address)).equal(ethers.constants.WeiPerEther)
    expect(await upToken2.balanceOf(addr2.address)).equal(0)
  })
})
