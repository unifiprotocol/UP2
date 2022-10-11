// import { BN } from "@unifiprotocol/utils"
// import { expect } from "chai"
// import { Signer } from "ethers"
// import { ethers } from "hardhat"
// import { AlpacaBNBStrategy } from "../../../typechain-types"
// import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"

// describe("AlpacaBNBStrategy", function () {
//   let signer: Signer
//   let alpacaStrategy: AlpacaBNBStrategy
//   let addr1: SignerWithAddress

//   beforeEach(async () => {
//     const provider = new ethers.providers.JsonRpcProvider(
//       "https://data-seed-prebsc-2-s1.binance.org:8545/"
//     )
//     const myContract = await ethers.getContractAt(
//       "Vault",
//       "0xf9d32C5E10Dd51511894b360e6bD39D7573450F9",
//       signer
//     )
//     const AlpacaBNBStrategyCF = await ethers.getContractFactory("AlpacaBNBStrategy")
//     const [_signer] = await ethers.getSigners()
//     signer = _signer
//     const signerAddress = await signer.getAddress()

//     alpacaStrategy = await AlpacaBNBStrategyCF.deploy(
//       signerAddress,
//       signerAddress,
//       "0xf9d32C5E10Dd51511894b360e6bD39D7573450F9"
//     )
//   })

//   it("Should deposit BNB into Alpaca Contract", async () => {
//     await alpacaStrategy.address.deposit(ethers.utils.parseEther("5"), {
//       value: ethers.utils.parseEther("5")
//     })
//     expect(await alpacaStrategy.amountDeposited.toEqual(ethers.utils.parseEther("5")))
//   })
// })
