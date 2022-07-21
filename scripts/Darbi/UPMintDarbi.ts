import { task } from "hardhat/config"
import { generateGetterSetter } from "../Util"

task("UPMintDarbiDeploy", "Deploy UPMintDarbi contract")
  .addParam("up", "UP Address")
  .addParam("controller", "UPController Address")
  .setAction(async ({ up, controller }, hre) => {
    await hre.run("compile")

    const UPMintDarbiContract = await hre.ethers.getContractFactory("UPMintDarbi")
    const upMintDarbi = await UPMintDarbiContract.deploy(up, controller, "<SAFE_WITHDRAW_ADDRESS>")
    await upMintDarbi.deployed()

    console.log("UPMintDarbi -", upMintDarbi.address)
  })

generateGetterSetter("UPMintDarbi")
