"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const config_1 = require("hardhat/config");
(0, config_1.task)("UniswapHelper", "Deploy UniswapHelper library contract").setAction(async (_, hre) => {
    await hre.run("compile");
    const UniswapHelper = await hre.ethers.getContractFactory("UniswapHelper");
    const uniswapHelper = await UniswapHelper.deploy();
    await uniswapHelper.deployed();
    console.log("UniswapHelper -", uniswapHelper.address);
});
exports.default = {
    BSCTest: "0x91a8ee7d784aBDDeB6fb2A148E902036a6065c58"
};
