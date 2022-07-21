import { task } from "hardhat/config"
import { generateGetterSetter } from "../Util"

task("VanillaDeploy", "Deploy Vanilla contract").setAction(async (_, hre) => {
  await hre.run("compile")

  const Vanilla = await hre.ethers.getContractFactory("Vanilla")
  const vanilla = await Vanilla.deploy("<SAFE_WITHDRAW_ADDRESS>")
  await vanilla.deployed()

  console.log("Vanilla -", vanilla.address)
})

generateGetterSetter("Vanilla")
