import { task } from "hardhat/config"
import UniswapHelper from "../Libraries/UniswapHelper"
import { generateGetterSetter } from "../Util"

task("DarbiDeploy", "Deploy Darbi contract")
  .addParam("factory", "UTrade factory Address")
  .addParam("router", "Router factory Address")
  .addParam("weth", "weth Address")
  .addParam("controller", "UPController Address")
  .addParam("darbiminter", "UPMintDarbi Address")
  .setAction(async ({ factory, router, weth, controller, darbiminter }, hre) => {
    await hre.run("compile")

    const network = hre.network.name as keyof typeof UniswapHelper

    const DarbiContract = await hre.ethers.getContractFactory("Darbi", {
      libraries: {
        UniswapHelper: UniswapHelper[network]
      }
    })
    // const darbi = await DarbiContract.deploy(factory, router, weth, controller, darbiminter)
    // await darbi.deployed()

    // console.log("Darbi -", darbi.address)
  })

generateGetterSetter("Darbi", {
  libraries: {
    UniswapHelper
  }
})
