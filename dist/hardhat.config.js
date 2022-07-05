"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
require("dotenv").config();
require("@nomiclabs/hardhat-waffle");
require("@typechain/hardhat");
require("@nomiclabs/hardhat-ethers");
require("solidity-docgen");
const harmonytestnetpk = process.env.HARMONY_TESTNET_PRIVATE_KEY;
const harmonymainnetpk = process.env.HARMONY_MAINNET_PRIVATE_KEY;
const bsctestnetpk = process.env.BSC_TESTNET_PRIVATE_KEY;
// TASKS
require("./scripts/");
// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
exports.default = {
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
        }
    }
};
