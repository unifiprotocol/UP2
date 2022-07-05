"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const config_1 = require("hardhat/config");
(0, config_1.task)("FullMath", "Deploy FullMath library contract").setAction(async (_, hre) => {
    await hre.run("compile");
    const FullMath = await hre.ethers.getContractFactory("FullMath");
    const fullMath = await FullMath.deploy();
    await fullMath.deployed();
    console.log("FullMath -", fullMath.address);
});
exports.default = {
    BSCTest: "0x9c2ebbbbc9fe69a3c21170a2842224a24aa27f68"
};
