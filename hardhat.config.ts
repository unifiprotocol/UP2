require("dotenv").config()
import { task } from "hardhat/config"
import "@nomiclabs/hardhat-waffle"
import "@typechain/hardhat"
import "@nomiclabs/hardhat-ethers"
import "solidity-docgen"

const PRIVATE_KEY = process.env.PRIVATE_KEY

// TASKS
import "./scripts/"

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
export default {
  // solidity: "0.8.4",
  solidity: {
    compilers: [{ version: "0.8.4" }, { version: "0.6.6" }]
  },
  docgen: {
    pages: "files"
  },
  networks: {
    hardhat: {
      chainId: 1337
    },
    HarmonyTest: {
      chainId: 1666700000,
      url: "https://api.s0.b.hmny.io",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : []
    },
    HarmonyMain: {
      chainId: 1666600000,
      url: "https://api.harmony.one",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : []
    },
    BSCTest: {
      chainId: 97,
      url: "https://data-seed-prebsc-2-s1.binance.org:8545/",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : []
    }
  }
}
