"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const config_1 = require("hardhat/config");
const Util_1 = require("../Util");
(0, config_1.task)("UPMintDarbiDeploy", "Deploy UPMintDarbi contract")
    .addParam("up", "UP Address")
    .addParam("controller", "UPController Address")
    .setAction(async ({ up, controller }, hre) => {
    await hre.run("compile");
    const UPMintDarbiContract = await hre.ethers.getContractFactory("UPMintDarbi");
    const upMintDarbi = await UPMintDarbiContract.deploy(up, controller);
    await upMintDarbi.deployed();
    console.log("UPMintDarbi -", upMintDarbi.address);
});
(0, Util_1.generateGetterSetter)("UPMintDarbi");
