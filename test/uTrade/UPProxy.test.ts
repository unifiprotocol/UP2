import { ethers } from "hardhat"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { UP, UPController, UPProxy } from "../../typechain-types"
import { expect } from "chai"

describe("UPProxy", () => {
  let upToken: UP
  let upController: UPController
  let upProxy: UPProxy
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
      .then((factory) => factory.deploy(upToken.address))
      .then((instance) => instance.deployed())
    upProxy = await ethers
      .getContractFactory("UPProxy")
      .then((factory) => factory.deploy(upToken.address, upController.address))
      .then((instance) => instance.deployed())
    await upToken.grantRole(await upToken.MINT_ROLE(), upController.address)
    await upToken.grantRole(await upToken.MINT_ROLE(), upProxy.address)
    await upController.grantRole(await upController.REBALANCER_ROLE(), addr1.address)
  })

  it("Should be fetch basic token info through proxy", async () => {
    const [addr1] = await ethers.getSigners()

    const name = await upProxy.name()
    const symbol = await upProxy.symbol()
    const decimals = await upProxy.decimals()
    const totalSupply = await upProxy.totalSupply()

    const adminRoleNS = await upProxy.DEFAULT_ADMIN_ROLE()

    expect(name).equal("UP")
    expect(symbol).equal("UP")
    expect(decimals).equal(18)
    expect(totalSupply).equal(0)
    expect(await upProxy.hasRole(adminRoleNS, addr1.address)).equal(true)
  })

  describe("Mint/Burn", () => {
    let upTokenAddr2: UPProxy
    let addr1: SignerWithAddress
    let addr2: SignerWithAddress

    beforeEach(async () => {
      const [a1, a2] = await ethers.getSigners()
      upTokenAddr2 = upProxy.connect(a2)
      addr1 = a1
      addr2 = a2
    })

    it("Should mint 1 UP", async () => {
      const controllerRoleNS = await upToken.MINT_ROLE()
      await upToken.grantRole(controllerRoleNS, addr2.address)
      await upProxy.mint(addr2.address, ethers.constants.WeiPerEther)
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
  })
})
