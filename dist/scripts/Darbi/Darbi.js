"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const config_1 = require("hardhat/config");
const UniswapHelper_1 = __importDefault(require("../Libraries/UniswapHelper"));
const Util_1 = require("../Util");
(0, config_1.task)("DarbiDeploy", "Deploy Darbi contract")
    .addParam("factory", "UTrade factory Address")
    .addParam("router", "Router factory Address")
    .addParam("weth", "weth Address")
    .addParam("controller", "UPController Address")
    .addParam("darbiminter", "UPMintDarbi Address")
    .setAction(async ({ factory, router, weth, controller, darbiminter }, hre) => {
    await hre.run("compile");
    const network = hre.network.name;
    const DarbiContract = await hre.ethers.getContractFactory("Darbi", {
        libraries: {
            UniswapHelper: UniswapHelper_1.default[network]
        }
    });
    // const darbi = await DarbiContract.deploy(factory, router, weth, controller, darbiminter)
    // await darbi.deployed()
    // console.log("Darbi -", darbi.address)
});
(0, Util_1.generateGetterSetter)("Darbi", {
    libraries: {
        UniswapHelper: UniswapHelper_1.default
    }
});
