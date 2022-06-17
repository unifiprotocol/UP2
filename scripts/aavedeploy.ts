// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat")

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  await hre.run("compile")

  // We get the contract to deploy
  const AAVEStrategy = await hre.ethers.getContractFactory("AAVEStrategy")
  const aaveStrategy = await AAVEStrategy.deploy(
    "0xcf664087a5bb0237a0bad6742852ec6c8d69a27a",
    "0x929ec64c34a17401f460460d4b9390518e5b473e",
    "0x794a61358d6845594f94dc1db02a252b5b4814ad",
    "0xe86b52ce2e4068ade71510352807597408998a69",
    "0x69fa688f1dc47d4b5d8029d5a35fb7a548310654",
    "0x6d80113e533a2c0fe82eabd35f1875dcea89ea97"
  )

  await aaveStrategy.deployed()

  console.log("AAVE Harmony Main Net has been deployed to:", aaveStrategy.address)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
