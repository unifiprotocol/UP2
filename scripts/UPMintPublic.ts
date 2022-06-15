import { task } from "hardhat/config"
import { generateGetterSetter } from "./Util"

task("UPMintPublicDeploy", "Deploy UPMintPublic contract")
  .addParam("up", "UP Address")
  .addParam("controller", "UPController Address")
  .addOptionalParam("mintRate", "mintRate = 5 = 5%", "5")
  .setAction(async ({ up, controller, mintRate }, hre) => {
    await hre.run("compile")

    const UPMintPublicContract = await hre.ethers.getContractFactory("UPMintPublic")
    const upMintPublic = await UPMintPublicContract.deploy(up, controller, mintRate)
    await upMintPublic.deployed()

    console.log("UPMintPublic -", upMintPublic.address)
  })

generateGetterSetter("UPMintPublic")
