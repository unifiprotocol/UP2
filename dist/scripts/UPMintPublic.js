"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const config_1 = require("hardhat/config");
const Util_1 = require("./Util");
(0, config_1.task)("UPMintPublicDeploy", "Deploy UPMintPublic contract")
    .addParam("up", "UP Address")
    .addParam("controller", "UPController Address")
    .addOptionalParam("mintRate", "mintRate = 5 = 5%", "5")
    .setAction(async ({ up, controller, mintRate }, hre) => {
    await hre.run("compile");
    const UPMintPublicContract = await hre.ethers.getContractFactory("UPMintPublic");
    const upMintPublic = await UPMintPublicContract.deploy(up, controller, mintRate);
    await upMintPublic.deployed();
    console.log("UPMintPublic -", upMintPublic.address);
});
(0, Util_1.generateGetterSetter)("UPMintPublic");
