import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { expect } from "chai"
import { ethers } from "hardhat"
import { UP } from "../typechain-types"

describe("UPv2", function () {
  let upToken: UP

  beforeEach(async () => {
    upToken = await ethers
      .getContractFactory("UP")
      .then((factory) => factory.deploy())
      .then((instance) => instance.deployed())
  })

  it("Should assert token basic info", async () => {
    const [addr1] = await ethers.getSigners()

    const name = await upToken.name()
    const symbol = await upToken.symbol()
    const decimals = await upToken.decimals()
    const totalSupply = await upToken.totalSupply()
    const totalBurn = await upToken.totalBurnt()

    const adminRoleNS = await upToken.DEFAULT_ADMIN_ROLE()

    expect(name).equal("UP")
    expect(symbol).equal("UP")
    expect(decimals).equal(18)
    expect(totalSupply).equal(0)
    expect(totalBurn).equal(0)
    expect(await upToken.hasRole(adminRoleNS, addr1.address)).equal(true)
  })

  describe("Mint/Burn", () => {
    let upTokenAddr2: UP
    let addr2: SignerWithAddress

    beforeEach(async () => {
      const [, a2] = await ethers.getSigners()
      upTokenAddr2 = upToken.connect(a2)
      addr2 = a2
    })

    it("Should mint 1 UP", async () => {
      const controllerRoleNS = await upToken.CONTROLLER_ROLE()
      await upToken.grantRole(controllerRoleNS, addr2.address)
      await upTokenAddr2.mint(addr2.address, ethers.constants.WeiPerEther)
      expect(await upTokenAddr2.totalSupply()).equal(ethers.constants.WeiPerEther)
      expect(await upTokenAddr2.balanceOf(addr2.address)).equal(ethers.constants.WeiPerEther)
    })

    it("Should mint 1 UP and burn it", async () => {
      const controllerRoleNS = await upToken.CONTROLLER_ROLE()
      await upToken.grantRole(controllerRoleNS, addr2.address)
      await upTokenAddr2.mint(addr2.address, ethers.constants.WeiPerEther)
      await upTokenAddr2.burn(ethers.constants.WeiPerEther)
      expect(await upTokenAddr2.totalSupply()).equal(0)
      expect(await upTokenAddr2.totalBurnt()).equal(ethers.constants.WeiPerEther)
      expect(await upTokenAddr2.balanceOf(addr2.address)).equal(0)
    })

    it("Should mint 1 UP and burn it using burnFrom", async () => {
      const controllerRoleNS = await upToken.CONTROLLER_ROLE()
      await upToken.grantRole(controllerRoleNS, addr2.address)
      await upTokenAddr2.mint(addr2.address, ethers.constants.WeiPerEther)
      await upTokenAddr2.approve(addr2.address, ethers.constants.WeiPerEther)
      await upTokenAddr2.burnFrom(addr2.address, ethers.constants.WeiPerEther)
      expect(await upTokenAddr2.totalSupply()).equal(0)
      expect(await upTokenAddr2.totalBurnt()).equal(ethers.constants.WeiPerEther)
      expect(await upTokenAddr2.allowance(addr2.address, addr2.address)).equal(0)
      expect(await upTokenAddr2.balanceOf(addr2.address)).equal(0)
    })
  })

  describe("AccessControl", () => {
    it("Should grant CONTROLLER_ROLE", async () => {
      const [, addr2] = await ethers.getSigners()
      const controllerRoleNS = await upToken.CONTROLLER_ROLE()
      await upToken.grantRole(controllerRoleNS, addr2.address)
      expect(await upToken.hasRole(controllerRoleNS, addr2.address)).equal(true)
    })

    it("CONTROLLER_ROLE should be able to mint tokens", async () => {
      const [, addr2] = await ethers.getSigners()
      const controllerRoleNS = await upToken.CONTROLLER_ROLE()
      await upToken.grantRole(controllerRoleNS, addr2.address)
      const upAddr2 = upToken.connect(addr2)
      await upAddr2.mint(addr2.address, 1)
      expect(await upAddr2.totalSupply()).equal(1)
      expect(await upAddr2.balanceOf(addr2.address)).equal(1)
    })

    it("CONTROLLER_ROLE account shouldn't be able to assing roles", async () => {
      const [, addr2, addr3] = await ethers.getSigners()
      const controllerRoleNS = await upToken.CONTROLLER_ROLE()
      await upToken.grantRole(controllerRoleNS, addr2.address)
      const upAddr2 = upToken.connect(addr2)
      await expect(upAddr2.grantRole(controllerRoleNS, addr3.address)).to.be.reverted
      expect(await upAddr2.getRoleAdmin(controllerRoleNS)).equal(ethers.constants.HashZero)
    })

    it("ADMIN_ROLE shouldn't be able to mint tokens", async () => {
      const [, addr2] = await ethers.getSigners()
      await expect(upToken.mint(addr2.address, 1)).revertedWith("UP: ONLY_CONTROLLER")
    })

    it("3rd party shouldn't be able to mint tokens", async () => {
      const [, , addr3] = await ethers.getSigners()
      const upAddr3 = upToken.connect(addr3)
      await expect(upAddr3.mint(addr3.address, 1)).revertedWith("UP: ONLY_CONTROLLER")
    })
  })
})
