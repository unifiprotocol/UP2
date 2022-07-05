"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const hardhat_1 = require("hardhat");
describe("Darbi", () => {
    let darbiContract;
    let unpermissionedDarbiContract;
    let admin;
    let unpermissionedAccount;
    const MEANINGLESS_ADDRESS = "0xA38395b264f232ffF4bb294b5947092E359dDE88";
    const MEANINGLESS_AMOUNT = "10000";
    beforeEach(async () => {
        const lib = await hardhat_1.ethers.getContractFactory("UniswapHelper").then((cf) => cf.deploy());
        const DarbiFactory = await hardhat_1.ethers.getContractFactory("Darbi", {
            libraries: {
                UniswapHelper: lib.address
            }
        });
        darbiContract = await DarbiFactory.deploy(hardhat_1.ethers.constants.AddressZero, hardhat_1.ethers.constants.AddressZero, hardhat_1.ethers.constants.AddressZero, hardhat_1.ethers.constants.AddressZero, hardhat_1.ethers.constants.AddressZero, hardhat_1.ethers.constants.AddressZero, hardhat_1.ethers.constants.AddressZero, hardhat_1.ethers.constants.AddressZero, {
            gasLimit: 29000000,
            gasPrice: 77233358200
        });
        const [_admin, _unpermissionedAccount] = await hardhat_1.ethers.getSigners();
        admin = _admin;
        unpermissionedAccount = _unpermissionedAccount;
        unpermissionedDarbiContract = darbiContract.connect(unpermissionedAccount);
    });
    describe("getters and setters", async () => {
        it("setFactory should fail due to unpermissioned account", async () => {
            (0, chai_1.expect)(await unpermissionedDarbiContract.setFactory(MEANINGLESS_ADDRESS)).to.be.reverted;
        });
        it("setFactory should fail due to invalid address (zero)", async () => {
            (0, chai_1.expect)(await darbiContract.setFactory(hardhat_1.ethers.constants.AddressZero)).to.be.reverted;
        });
        it("setFactory should change factory contract address", async () => {
            await darbiContract.setFactory(MEANINGLESS_ADDRESS);
            (0, chai_1.expect)(await darbiContract.factory()).equal(MEANINGLESS_ADDRESS, "Factory address should have been changed");
        });
        it("setRouter should fail due to unpermissioned account", async () => {
            (0, chai_1.expect)(await unpermissionedDarbiContract.setRouter(MEANINGLESS_ADDRESS)).to.be.reverted;
        });
        it("setRouter should fail due to invalid address (zero)", async () => {
            (0, chai_1.expect)(await darbiContract.setRouter(hardhat_1.ethers.constants.AddressZero)).to.be.reverted;
        });
        it("setRouter should change router contract address", async () => {
            await darbiContract.setRouter(MEANINGLESS_ADDRESS);
            (0, chai_1.expect)(await darbiContract.router()).equal(MEANINGLESS_ADDRESS, "Router address should have been changed");
        });
        it("setDarbiMinter should fail due to unpermissioned account", async () => {
            (0, chai_1.expect)(await unpermissionedDarbiContract.setDarbiMinter(MEANINGLESS_ADDRESS)).to.be.reverted;
        });
        it("setDarbiMinter should fail due to invalid address (zero)", async () => {
            (0, chai_1.expect)(await darbiContract.setDarbiMinter(hardhat_1.ethers.constants.AddressZero)).to.be.reverted;
        });
        it("setDarbiMinter should change darbi minter contract address", async () => {
            await darbiContract.setDarbiMinter(MEANINGLESS_ADDRESS);
            (0, chai_1.expect)(await darbiContract.DARBI_MINTER()).equal(MEANINGLESS_ADDRESS, "Darbi minter address should have been changed");
        });
        it("setArbitrageThreshold should fail due to unpermissioned account", async () => {
            (0, chai_1.expect)(await unpermissionedDarbiContract.setArbitrageThreshold(0)).to.be.reverted;
        });
        it("setArbitrageThreshold should fail due to invalid amount (zero)", async () => {
            (0, chai_1.expect)(await darbiContract.setArbitrageThreshold(0)).to.be.reverted;
        });
        it("setArbitrageThreshold should change arbitrage threshold", async () => {
            await darbiContract.setArbitrageThreshold(MEANINGLESS_AMOUNT);
            (0, chai_1.expect)(await darbiContract.arbitrageThreshold()).equals(MEANINGLESS_AMOUNT, "Arbitrage threshold should have been changed");
        });
        it("setGasRefund should fail due to unpermissioned account", async () => { });
        it("setGasRefund should change gas refund amount", async () => { });
    });
});
