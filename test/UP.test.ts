import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { expect } from "chai"
import { ethers } from "hardhat"
import { UP, UPController } from "../typechain-types"

describe("UPv2", function () {
  let upToken: UP
  let addr1: SignerWithAddress

  beforeEach(async () => {
    const [a1] = await ethers.getSigners()
    addr1 = a1
    upToken = await ethers
      .getContractFactory("UP")
      .then((factory) => factory.deploy())
      .then((instance) => instance.deployed())
  })

  it("Should assert token basic info", async () => {
    const name = await upToken.name()
    const symbol = await upToken.symbol()
    const decimals = await upToken.decimals()
    const totalSupply = await upToken.totalSupply()

    const adminRoleNS = await upToken.DEFAULT_ADMIN_ROLE()

    expect(name).equal("UP")
    expect(symbol).equal("UP")
    expect(decimals).equal(18)
    expect(totalSupply).equal(0)
    expect(await upToken.hasRole(adminRoleNS, addr1.address)).equal(true)
  })

  it("Should set a new controller address", async () => {
    expect(await upToken.UP_CONTROLLER()).eq(ethers.constants.AddressZero)
    await upToken.setController(addr1.address)
    expect(await upToken.UP_CONTROLLER()).eq(addr1.address)
  })

  describe("Mint/Burn", () => {
    let upTokenAddr2: UP
    let addr1: SignerWithAddress
    let addr2: SignerWithAddress
    let addr3: SignerWithAddress

    beforeEach(async () => {
      const [a1, a2, a3] = await ethers.getSigners()
      upTokenAddr2 = upToken.connect(a2)
      addr1 = a1
      addr2 = a2
      addr3 = a3
    })

    it("Should mint 1 UP", async () => {
      const controllerRoleNS = await upToken.MINT_ROLE()
      await upToken.grantRole(controllerRoleNS, addr2.address)
      await upTokenAddr2.mint(addr2.address, ethers.constants.WeiPerEther)
      expect(await upTokenAddr2.totalSupply()).equal(ethers.constants.WeiPerEther)
      expect(await upTokenAddr2.balanceOf(addr2.address)).equal(ethers.constants.WeiPerEther)
    })

    it("Should mint 1 UP and transfer it", async () => {
      const controllerRoleNS = await upToken.MINT_ROLE()
      await upToken.grantRole(controllerRoleNS, addr2.address)
      await upTokenAddr2.mint(addr2.address, ethers.constants.WeiPerEther)
      await upTokenAddr2.transfer(addr1.address, ethers.constants.WeiPerEther)
      expect(await upTokenAddr2.balanceOf(addr1.address)).equal(ethers.constants.WeiPerEther)
      expect(await upTokenAddr2.balanceOf(addr2.address)).equal(0)
    })

    it("Should mint 1 UP and burn it", async () => {
      const controllerRoleNS = await upToken.MINT_ROLE()
      await upToken.grantRole(controllerRoleNS, addr2.address)
      await upTokenAddr2.mint(addr2.address, ethers.constants.WeiPerEther)
      expect(await upTokenAddr2.totalSupply()).equal(ethers.constants.WeiPerEther)
      await upTokenAddr2.burn(ethers.constants.WeiPerEther)
      expect(await upTokenAddr2.totalSupply()).equal(0)
      expect(await upTokenAddr2.balanceOf(addr2.address)).equal(0)
    })

    it("Should mint 1 UP and burn it using burnFrom", async () => {
      const controllerRoleNS = await upToken.MINT_ROLE()
      await upToken.grantRole(controllerRoleNS, addr2.address)
      await upTokenAddr2.mint(addr2.address, ethers.constants.WeiPerEther)
      await upTokenAddr2.approve(addr2.address, ethers.constants.WeiPerEther)
      expect(await upTokenAddr2.allowance(addr2.address, addr2.address)).equal(
        ethers.constants.WeiPerEther
      )
      await upTokenAddr2.burnFrom(addr2.address, ethers.constants.WeiPerEther)
      expect(await upTokenAddr2.totalSupply()).equal(0)
      expect(await upTokenAddr2.allowance(addr2.address, addr2.address)).equal(0)
      expect(await upTokenAddr2.balanceOf(addr2.address)).equal(0)
    })

    it("Should mint UP and send the value to LEGACY_MINT_ROLE", async () => {
      await upToken.grantRole(await upToken.MINT_ROLE(), addr1.address)
      await upToken.grantRole(await upToken.LEGACY_MINT_ROLE(), addr1.address)
      await upToken.setController(addr3.address)
      const prevBalance = await upToken.provider.getBalance(addr3.address)
      await upToken.mint(addr1.address, ethers.constants.WeiPerEther, { value: 5 })
      expect(await upToken.provider.getBalance(addr3.address)).equal(prevBalance.add(5))
    })

    it("Should mint UP and send not send native tokens because no controller set", async () => {
      await upToken.grantRole(await upToken.MINT_ROLE(), addr1.address)
      await upToken.grantRole(await upToken.LEGACY_MINT_ROLE(), addr1.address)
      const prevBalance = await upToken.provider.getBalance(addr3.address)
      await upToken.mint(addr1.address, ethers.constants.WeiPerEther, { value: 5 })
      expect(await upToken.provider.getBalance(addr3.address)).equal(prevBalance)
    })
  })

  describe("AccessControl", () => {
    it("Should grant MINT_ROLE", async () => {
      const [, addr2, addr3] = await ethers.getSigners()
      const controllerRoleNS = await upToken.MINT_ROLE()
      await upToken.grantRole(controllerRoleNS, addr2.address)
      await upToken.grantRole(controllerRoleNS, addr3.address)
      expect(await upToken.hasRole(controllerRoleNS, addr2.address)).equal(true)
      expect(await upToken.hasRole(controllerRoleNS, addr3.address)).equal(true)
    })

    it("MINT_ROLE should be able to mint tokens", async () => {
      const [, addr2] = await ethers.getSigners()
      const controllerRoleNS = await upToken.MINT_ROLE()
      await upToken.grantRole(controllerRoleNS, addr2.address)
      const upAddr2 = upToken.connect(addr2)
      await upAddr2.mint(addr2.address, 1)
      expect(await upAddr2.totalSupply()).equal(1)
      expect(await upAddr2.balanceOf(addr2.address)).equal(1)
    })

    it("MINT_ROLE account shouldn't be able to assing roles", async () => {
      const [, addr2, addr3] = await ethers.getSigners()
      const controllerRoleNS = await upToken.MINT_ROLE()
      await upToken.grantRole(controllerRoleNS, addr2.address)
      const upAddr2 = upToken.connect(addr2)
      await expect(upAddr2.grantRole(controllerRoleNS, addr3.address)).to.be.reverted
      expect(await upAddr2.getRoleAdmin(controllerRoleNS)).equal(ethers.constants.HashZero)
    })

    it("ADMIN_ROLE shouldn't be able to mint tokens", async () => {
      const [, addr2] = await ethers.getSigners()
      await expect(upToken.mint(addr2.address, 1)).revertedWith("ONLY_MINT")
    })

    it("3rd party shouldn't be able to mint tokens", async () => {
      const [, , addr3] = await ethers.getSigners()
      const upAddr3 = upToken.connect(addr3)
      await expect(upAddr3.mint(addr3.address, 1)).revertedWith("ONLY_MINT")
    })
  })

  describe("Legacy mint logic", () => {
    let upController: UPController

    beforeEach(async () => {
      upController = await ethers
        .getContractFactory("UPController")
        .then((factory) => factory.deploy(upToken.address))
        .then((instance) => instance.deployed())
      await upToken.grantRole(await upToken.MINT_ROLE(), addr1.address)
      await upToken.grantRole(await upToken.MINT_ROLE(), upController.address)
    })

    it("Should mint based in virtualPrice #0", async () => {
      await addr1.sendTransaction({
        to: upController.address,
        value: ethers.utils.parseEther("5")
      })
      await upToken.mint(upController.address, ethers.utils.parseEther("2"))
      const sendValue = ethers.utils.parseEther("5")
      const virtualPrice = ethers.utils.parseEther("2.5")
      const expectedMint = sendValue.mul(ethers.utils.parseEther("1")).div(virtualPrice)
      await upToken.grantRole(await upToken.LEGACY_MINT_ROLE(), addr1.address)
      await upToken.setController(upController.address)
      await upToken.mint(addr1.address, 0, { value: sendValue })
      expect(await upToken.balanceOf(addr1.address)).equal(expectedMint)
    })

    it("Should mint based in virtualPrice #1", async () => {
      await addr1.sendTransaction({
        to: upController.address,
        value: ethers.utils.parseEther("5")
      })
      await upToken.mint(upController.address, ethers.utils.parseEther("4"))
      const sendValue = ethers.utils.parseEther("5")
      const virtualPrice = ethers.utils.parseEther("1.25")
      const expectedMint = sendValue.mul(ethers.utils.parseEther("1")).div(virtualPrice)
      await upToken.grantRole(await upToken.LEGACY_MINT_ROLE(), addr1.address)
      await upToken.setController(upController.address)
      await upToken.mint(addr1.address, 0, { value: sendValue })
      expect(await upToken.balanceOf(addr1.address)).equal(expectedMint)
    })

    it("Should forward native balances to UP_CONTROLLER", async () => {
      await upToken.setController(upController.address)
      await addr1.sendTransaction({
        to: upToken.address,
        value: ethers.utils.parseEther("5")
      })
      expect(await upToken.provider.getBalance(upToken.address)).equal(ethers.utils.parseEther("5"))
      await upToken.withdrawFunds()
      expect(await upToken.provider.getBalance(upController.address)).equal(
        ethers.utils.parseEther("5")
      )
    })

    it("Should fail forwarding native balances to UP_CONTROLLER because not UP_CONTROLLER", async () => {
      await expect(upToken.withdrawFunds()).to.be.reverted
    })
  })
})
