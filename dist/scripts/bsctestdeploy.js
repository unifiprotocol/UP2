"use strict";
// const hre = require("hardhat")
// async function main() {
//   await hre.run("compile")
//   // First we deploy UP Token
//   const UPToken = await hre.ethers.getContractFactory("UP")
//   const upToken = await UPToken.deploy()
//   await upToken.deployed()
//   console.log("UP V2 has been deployed to", upToken.address)
//   //Then UPController
//   const UPController = await hre.ethers.getContractFactory("UPController")
//   const upController = await UPController.deploy(upToken.address)
//   await upController.deployed()
//   console.log("UP V2 Controller has been deployed to", upController.address)
//   //Then UPMintPublic
//   const UPMintPublic = await hre.ethers.getContractFactory("UPMintPublic")
//   const upMintPublic = await UPMintPublic.deploy(upToken.address, upController.address, 95)
//   await upMintPublic.deployed()
//   console.log("UP V2 Public Mint Contract has been deployed to", upMintPublic.address)
//   //Then Darbi
//   //Then UpMintDarbi
//   //Then Strategy
// }
// // We recommend this pattern to be able to use async/await everywhere
// // and properly handle errors.
// main()
//   .then(() => process.exit(0))
//   .catch((error) => {
//     console.error(error)
//     process.exit(1)
//   })
