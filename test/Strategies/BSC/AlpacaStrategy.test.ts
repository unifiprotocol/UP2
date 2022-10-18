import { BN } from "@unifiprotocol/utils"
import { expect } from "chai"
import { Signer } from "ethers"
import { ethers } from "hardhat"
import { AlpacaBNBStrategy, IVault } from "../../../typechain-types"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"

describe("AlpacaBNBStrategy", function () {
  let signer: Signer
  let addr1: Signer
  let addr2: Signer
  let alpacaStrategy: AlpacaBNBStrategy
  let alpacaVault: IVault
  console.log("Variable Got")

  beforeEach(async () => {
    ;[signer, addr1, addr2] = await ethers.getSigners()
    const addr1Address = await addr1.getAddress()
    const addr2Address = await addr2.getAddress()
    const alpacaVaultAddress = "0xd7D069493685A581d27824Fc46EdA46B7EfC0063"
    const alpacaFactory = await ethers.getContractFactory("AlpacaBNBStrategy")
    alpacaStrategy = await alpacaFactory.deploy(addr1Address, addr1Address, alpacaVaultAddress)
  })

  it("Should read correct values on deploy", async () => {
    const addr1Address = await addr1.getAddress()
    const amountDeposited = await alpacaStrategy.amountDeposited()
    const addr1deploy = await alpacaStrategy.rebalancer()
    const alpacaVaultDeploy = await alpacaStrategy.alpacaVault()
    const alpacaVaultAddress = "0xd7D069493685A581d27824Fc46EdA46B7EfC0063"
    expect(amountDeposited).equal(0)
    console.log("Amount Deposited is 0 at deploy")
    expect(addr1deploy).equal(addr1Address)
    console.log("The Rebalancer Address is set properly on deploy")
    expect(alpacaVaultDeploy).equal(alpacaVaultAddress)
    console.log("The Alpaca Vault is set properly on deploy")
  })

  it("setAlpacaVault should change AlpacaVault", async () => {
    const addr1Address = await addr1.getAddress()
    await alpacaStrategy.setAlpacaVault(addr1Address)
    expect(await alpacaStrategy.alpacaVault()).equals(addr1Address)
  })
  it("setUPController should fail from an unpermissioned account", async () => {
    const signerAddress = await signer.getAddress()
    const addr2signer = alpacaStrategy.connect(addr2)
    await expect(addr2signer.setAlpacaVault(signerAddress)).revertedWith("ONLY_ADMIN")
  })

  // it("should deposit", async () => {
  //   const addr1Signer = alpacaStrategy.connect(addr1)
  //   const alpacaVaultAddress = "0xd7D069493685A581d27824Fc46EdA46B7EfC0063"
  //   await addr1Signer.provider.getBalance(addr1Signer.address).then(console.log)
  //   const alpacaVault = await ethers.getContractAt("IVault", alpacaVaultAddress)
  //   expect(
  //     await addr1Signer.deposit(ethers.utils.parseEther("2"), {
  //       value: ethers.utils.parseEther("2")
  //     })
  //   )
  //   // expect(await addr1Signer.provider.getBalance(addr1Signer.address)).equal(
  //   //   ethers.utils.parseEther("8")
  //   // )
  //   const IBBNBbalance = await alpacaVault.balanceOf(alpacaStrategy.address) // check balance of addr1signer + signer
  //   console.log(IBBNBbalance)
  // })

  it("deposit function should revert unless it is from Rebalancer", async () => {
    const addr2Signer = alpacaStrategy.connect(addr2)
    await expect(
      addr2Signer.deposit(ethers.utils.parseEther("2"), {
        value: ethers.utils.parseEther("2")
      })
    ).revertedWith("ONLY_REBALANCER")
  })
  it("deposit function should revert if parameter does not match msg.value", async () => {
    await expect(
      alpacaStrategy.deposit(ethers.utils.parseEther("1"), {
        value: ethers.utils.parseEther("2")
      })
    ).revertedWith("Alpaca Strategy: Deposit Value Parameter does not equal payable amount")
  })
  it("withdraw function should revert if amount is greater than amountdeposited", async () => {
    await expect(alpacaStrategy.withdraw(ethers.utils.parseEther("1"))).revertedWith(
      "Alpaca Strategy: Amount Requested to Withdraw is Greater Than Amount Deposited"
    )
  })

  // it("Should deposit BNB into Alpaca Contract", async () => {
  //   await alpacaStrategy.address.deposit(ethers.utils.parseEther("5"), {
  //     value: ethers.utils.parseEther("5")
  //   })
  //   expect(await alpacaStrategy.amountDeposited.toEqual(ethers.utils.parseEther("5")))
  // })
})
