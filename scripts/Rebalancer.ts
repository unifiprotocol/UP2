import { task } from "hardhat/config"
import { generateGetterSetter } from "./Util"

task("RebalancerDeploy", "Deploy Rebalancer contract")
  .addParam("weth", "WETH Address")
  .addParam("up", "UP Address")
  .addParam("controller", "UPController Address")
  .addParam("strategy", "Strategy Address")
  .addParam("router", "UNIFI Router Address")
  .addParam("factory", "UNIFI Factory Address")
  .addParam("lp", "UNIFI LP Address")
  .addParam("darbi", "Darbi Address")
  .setAction(async ({ weth, up, controller, strategy, router, factory, lp, darbi }, hre) => {
    await hre.run("compile")

    const RebalancerContract = await hre.ethers.getContractFactory("Rebalancer")
    const rebalancer = await RebalancerContract.deploy(
      weth,
      up,
      controller,
      strategy,
      router,
      factory,
      lp,
      darbi
    )
    await rebalancer.deployed()

    console.log("Rebalancer -", rebalancer.address)
  })

generateGetterSetter("Rebalancer")
