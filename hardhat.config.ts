require("dotenv").config()
import { task } from "hardhat/config"
import "@nomiclabs/hardhat-waffle"
import "@typechain/hardhat"
import "@nomiclabs/hardhat-ethers"
import "solidity-docgen"

const harmonytestnetpk = process.env.HARMONY_TESTNET_PRIVATE_KEY
const harmonymainnetpk = process.env.HARMONY_MAINNET_PRIVATE_KEY
const bsctestnetpk = process.env.BSC_TESTNET_PRIVATE_KEY

// TASKS
// import "./scripts/"

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
export default {
  // solidity: "0.8.4",
  solidity: {
    compilers: [{ version: "0.8.4" }]
  },
  docgen: {
    pages: "files"
  },
  networks: {
    HarmonyTest: {
      chainId: 1666700000,
      url: "https://api.s0.b.hmny.io",
      accounts: harmonytestnetpk ? [harmonytestnetpk] : []
    },
    HarmonyMain: {
      chainId: 1666600000,
      url: "https://api.harmony.one",
      accounts: harmonymainnetpk ? [harmonymainnetpk] : []
    },
    BSCTest: {
      chainId: 97,
      url: "https://data-seed-prebsc-2-s1.binance.org:8545/",
      accounts: bsctestnetpk ? [bsctestnetpk] : []
    },
    hardhat: {
      forking: {
        url: "https://proxy.unifiprotocol.com/rpc-internal/binance"
      }
    }
  },
  etherscan: {
    apiKey: {
      mainnet: "RX5F9AXT5BSG696ZUYC4IVENDAGGPSQ9I1",
      ropsten: "6329MS2FHP9NCKF6DKPDMR5RIE3HYCYGW1",
      bscTestnet: "BC9318STPGVMNCWWBSKTUTZ5CTVK8DDD1B",
      bsc: "2N8MMDJJRIE9661UDSJXICDHEN5N4I4ZD1",
      polygon: "C8YFTAEB68WSSEQVKZQENPY98DH7VKCGYV",
      avalanche: "Q7HS4I9BHTUU761CVGUFK79SY5NBYVNCTN",
      opera: "71ZCRD5TYV9SPK8XTSPYAMI7XTUQWIC1V2"
    }
  }
}
