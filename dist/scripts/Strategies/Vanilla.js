"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const config_1 = require("hardhat/config");
const Util_1 = require("../Util");
(0, config_1.task)("VanillaDeploy", "Deploy Vanilla contract").setAction(async (_, hre) => {
    await hre.run("compile");
    const Vanilla = await hre.ethers.getContractFactory("Vanilla");
    const vanilla = await Vanilla.deploy();
    await vanilla.deployed();
    console.log("Vanilla -", vanilla.address);
});
(0, Util_1.generateGetterSetter)("Vanilla");
