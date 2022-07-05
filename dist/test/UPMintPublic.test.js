"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const hardhat_1 = require("hardhat");
const chai_1 = require("chai");
describe("UPMintPublic", () => {
    let upToken;
    let upController;
    let upMintPublic;
    let addr1;
    beforeEach(async () => {
        const [a1] = await hardhat_1.ethers.getSigners();
        addr1 = a1;
        upToken = await hardhat_1.ethers
            .getContractFactory("UP")
            .then((factory) => factory.deploy())
            .then((instance) => instance.deployed());
        upController = await hardhat_1.ethers
            .getContractFactory("UPController")
            .then((factory) => factory.deploy(upToken.address))
            .then((instance) => instance.deployed());
        upMintPublic = await hardhat_1.ethers
            .getContractFactory("UPMintPublic")
            .then((factory) => factory.deploy(upToken.address, upController.address, 5))
            .then((instance) => instance.deployed());
        await upToken.grantRole(await upToken.MINT_ROLE(), addr1.address);
        await upToken.grantRole(await upToken.MINT_ROLE(), upMintPublic.address);
    });
    it('Should set a new "mintRate"', async () => {
        await upMintPublic.setMintRate(100);
        (0, chai_1.expect)(await upMintPublic.mintRate()).equal(100);
    });
    it('Shouldnt set a new "mintRate" because not enough permissions', async () => {
        const [, addr2] = await hardhat_1.ethers.getSigners();
        const addr2UpController = upMintPublic.connect(addr2);
        await (0, chai_1.expect)(addr2UpController.setMintRate(100)).revertedWith("Ownable: caller is not the owner");
    });
    it('Should revert "setMintRate" because value is out of threshold #0', async () => {
        await (0, chai_1.expect)(upMintPublic.setMintRate(101)).revertedWith("MINT_RATE_GT_100");
    });
    it('Should revert "setMintRate" because value is out of threshold #1', async () => {
        await (0, chai_1.expect)(upMintPublic.setMintRate(0)).revertedWith("MINT_RATE_EQ_0");
    });
    describe("MintUP", () => {
        let addr2;
        let addr2UpMintPublic;
        beforeEach(async () => {
            const [, a2] = await hardhat_1.ethers.getSigners();
            addr2 = a2;
            addr2UpMintPublic = upMintPublic.connect(a2);
        });
        it("Should mint UP at premium rates #0", async () => {
            await addr1.sendTransaction({
                to: upController.address,
                value: hardhat_1.ethers.utils.parseEther("5")
            });
            await upToken.mint(upController.address, hardhat_1.ethers.utils.parseEther("2"));
            await addr2UpMintPublic.mintUP(addr2.address, { value: hardhat_1.ethers.utils.parseEther("100") });
            (0, chai_1.expect)(await upToken.balanceOf(addr2.address)).equal(hardhat_1.ethers.utils.parseEther("237.5"));
            (0, chai_1.expect)(await upController.provider.getBalance(upController.address)).equal(hardhat_1.ethers.utils.parseEther("100").add(hardhat_1.ethers.utils.parseEther("5")));
        });
        it("Should mint UP at premium rates #1", async () => {
            await addr1.sendTransaction({
                to: upController.address,
                value: hardhat_1.ethers.utils.parseEther("5")
            });
            await upToken.mint(upController.address, hardhat_1.ethers.utils.parseEther("2"));
            await addr2UpMintPublic.mintUP(addr2.address, { value: hardhat_1.ethers.utils.parseEther("5") });
            (0, chai_1.expect)(await upToken.balanceOf(addr2.address)).equal(hardhat_1.ethers.utils.parseEther("11.875"));
            (0, chai_1.expect)(await upController.provider.getBalance(upController.address)).equal(hardhat_1.ethers.utils.parseEther("5").add(hardhat_1.ethers.utils.parseEther("5")));
        });
        it("Should mint UP at premium rates #2", async () => {
            await addr1.sendTransaction({
                to: upController.address,
                value: hardhat_1.ethers.utils.parseEther("5")
            });
            await upToken.mint(upMintPublic.address, hardhat_1.ethers.utils.parseEther("2"));
            await addr2UpMintPublic.mintUP(addr2.address, { value: hardhat_1.ethers.utils.parseEther("31") });
            (0, chai_1.expect)(await upToken.balanceOf(addr2.address)).equal(hardhat_1.ethers.utils.parseEther("73.625"));
            (0, chai_1.expect)(await upController.provider.getBalance(upController.address)).equal(hardhat_1.ethers.utils.parseEther("31").add(hardhat_1.ethers.utils.parseEther("5")));
        });
        it("Should mint UP at premium rates #3", async () => {
            await addr1.sendTransaction({
                to: upController.address,
                value: hardhat_1.ethers.utils.parseEther("5")
            });
            await upToken.mint(upMintPublic.address, hardhat_1.ethers.utils.parseEther("2"));
            await addr2UpMintPublic.mintUP(addr2.address, { value: hardhat_1.ethers.utils.parseEther("1233") });
            (0, chai_1.expect)(await upToken.balanceOf(addr2.address)).equal(hardhat_1.ethers.utils.parseEther("2928.375"));
            (0, chai_1.expect)(await upController.provider.getBalance(upController.address)).equal(hardhat_1.ethers.utils.parseEther("1233").add(hardhat_1.ethers.utils.parseEther("5")));
        });
        it("Should mint UP at premium rates #4", async () => {
            await addr1.sendTransaction({
                to: upController.address,
                value: hardhat_1.ethers.utils.parseEther("5")
            });
            await upToken.mint(upMintPublic.address, hardhat_1.ethers.utils.parseEther("2"));
            await addr2UpMintPublic.mintUP(addr2.address, { value: hardhat_1.ethers.utils.parseEther("999.1") });
            (0, chai_1.expect)(await upToken.balanceOf(addr2.address)).equal(hardhat_1.ethers.utils.parseEther("2372.8625"));
            (0, chai_1.expect)(await upController.provider.getBalance(upController.address)).equal(hardhat_1.ethers.utils.parseEther("999.1").add(hardhat_1.ethers.utils.parseEther("5")));
        });
        it("Should mint UP at premium rates #5", async () => {
            await hardhat_1.network.provider.send("hardhat_setBalance", [
                addr2.address,
                hardhat_1.ethers.utils.parseEther("99900").toHexString()
            ]);
            await addr1.sendTransaction({
                to: upController.address,
                value: hardhat_1.ethers.utils.parseEther("5")
            });
            await upToken.mint(upMintPublic.address, hardhat_1.ethers.utils.parseEther("2"));
            await addr2UpMintPublic.mintUP(addr2.address, { value: hardhat_1.ethers.utils.parseEther("91132.42") });
            (0, chai_1.expect)(await upToken.balanceOf(addr2.address)).equal(hardhat_1.ethers.utils.parseEther("216439.4975"));
            (0, chai_1.expect)(await upController.provider.getBalance(upController.address)).equal(hardhat_1.ethers.utils.parseEther("91132.42").add(hardhat_1.ethers.utils.parseEther("5")));
        });
        it("Should mint UP at premium rates #6", async () => {
            await addr1.sendTransaction({
                to: upController.address,
                value: hardhat_1.ethers.utils.parseEther("5")
            });
            await upToken.mint(upMintPublic.address, hardhat_1.ethers.utils.parseEther("4"));
            await addr2UpMintPublic.mintUP(addr2.address, { value: hardhat_1.ethers.utils.parseEther("999") });
            (0, chai_1.expect)(await upToken.balanceOf(addr2.address)).equal(hardhat_1.ethers.utils.parseEther("1186.3125"));
            (0, chai_1.expect)(await upController.provider.getBalance(upController.address)).equal(hardhat_1.ethers.utils.parseEther("999").add(hardhat_1.ethers.utils.parseEther("5")));
        });
        it("Should fail minting UP because payable value is zero", async () => {
            await (0, chai_1.expect)(upMintPublic.mintUP(addr1.address, { value: 0 })).revertedWith("INVALID_PAYABLE_AMOUNT");
        });
        it("Should mint zero UP because virtual price is zero and throw UP_PRICE_0", async () => {
            await (0, chai_1.expect)(upMintPublic.mintUP(addr1.address, { value: hardhat_1.ethers.utils.parseEther("100") })).revertedWith("UP_PRICE_0");
            (0, chai_1.expect)(await upToken.balanceOf(addr1.address)).equal(0);
        });
        it("Shouldn't mint up because contract is paused", async () => {
            await upMintPublic.pause();
            await (0, chai_1.expect)(upMintPublic.mintUP(addr1.address, { value: hardhat_1.ethers.utils.parseEther("100") })).revertedWith("Pausable: pause");
        });
        it("Should mint UP after pause and unpause", async () => {
            await addr1.sendTransaction({
                to: upController.address,
                value: hardhat_1.ethers.utils.parseEther("5")
            });
            await upToken.mint(upController.address, hardhat_1.ethers.utils.parseEther("2"));
            await upMintPublic.pause();
            await (0, chai_1.expect)(addr2UpMintPublic.mintUP(addr2.address, { value: hardhat_1.ethers.utils.parseEther("100") })).revertedWith("Pausable: pause");
            await upMintPublic.unpause();
            await addr2UpMintPublic.mintUP(addr2.address, { value: hardhat_1.ethers.utils.parseEther("100") });
            (0, chai_1.expect)(await upToken.balanceOf(addr2.address)).equal(hardhat_1.ethers.utils.parseEther("237.5"));
            (0, chai_1.expect)(await upController.provider.getBalance(upController.address)).equal(hardhat_1.ethers.utils.parseEther("100").add(hardhat_1.ethers.utils.parseEther("5")));
        });
    });
});
