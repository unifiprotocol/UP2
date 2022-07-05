"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const hardhat_1 = require("hardhat");
describe("UPMintDarbi", () => {
    let upToken;
    let upMintDarbi;
    let upController;
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
        upMintDarbi = await hardhat_1.ethers
            .getContractFactory("UPMintDarbi")
            .then((factory) => factory.deploy(upToken.address, upController.address))
            .then((instance) => instance.deployed());
        await upToken.grantRole(await upToken.MINT_ROLE(), upMintDarbi.address);
        await upMintDarbi.grantDarbiRole(addr1.address);
    });
    it("Should update controller address", async () => {
        const [, a2] = await hardhat_1.ethers.getSigners();
        (0, chai_1.expect)(await upMintDarbi.UP_CONTROLLER()).equal(upController.address);
        await (0, chai_1.expect)(upMintDarbi.updateController(a2.address))
            .emit(upMintDarbi, "UpdateController")
            .withArgs(a2.address);
        (0, chai_1.expect)(await upMintDarbi.UP_CONTROLLER()).equal(a2.address);
    });
    it("Should fail updating controller because ONLY_ADMIN", async () => {
        const [, a2] = await hardhat_1.ethers.getSigners();
        const addr2UpMintDarbi = upMintDarbi.connect(a2);
        await (0, chai_1.expect)(addr2UpMintDarbi.updateController(a2.address)).revertedWith("ONLY_ADMIN");
    });
    it("Should grant DARBi role", async () => {
        const darbiRoleNS = await upMintDarbi.DARBI_ROLE();
        const [, a2] = await hardhat_1.ethers.getSigners();
        (0, chai_1.expect)(await upMintDarbi.hasRole(darbiRoleNS, a2.address)).equal(false);
        await upMintDarbi.grantDarbiRole(a2.address);
        (0, chai_1.expect)(await upMintDarbi.hasRole(darbiRoleNS, a2.address)).equal(true);
    });
    it("Should revoke DARBi role", async () => {
        const darbiRoleNS = await upMintDarbi.DARBI_ROLE();
        const [, a2] = await hardhat_1.ethers.getSigners();
        await upMintDarbi.grantDarbiRole(a2.address);
        (0, chai_1.expect)(await upMintDarbi.hasRole(darbiRoleNS, a2.address)).equal(true);
        await upMintDarbi.revokeDarbiRole(a2.address);
        (0, chai_1.expect)(await upMintDarbi.hasRole(darbiRoleNS, a2.address)).equal(false);
    });
    it("Should fail granting DARBi role because ONLY_ADMIN", async () => {
        const [, a2] = await hardhat_1.ethers.getSigners();
        const addr2UpMintDarbi = upMintDarbi.connect(a2);
        await (0, chai_1.expect)(addr2UpMintDarbi.grantDarbiRole(a2.address)).revertedWith("ONLY_ADMIN");
    });
    describe("MintUP", () => {
        beforeEach(async () => {
            await upToken.grantRole(await upToken.MINT_ROLE(), addr1.address);
            await addr1.sendTransaction({
                to: upController.address,
                value: hardhat_1.ethers.utils.parseEther("5")
            });
            await upToken.mint(upController.address, hardhat_1.ethers.utils.parseEther("2"));
        });
        it("Should mint UP #0", async () => {
            await (0, chai_1.expect)(upMintDarbi.mintUP({ value: hardhat_1.ethers.utils.parseEther("1") }))
                .emit(upMintDarbi, "DarbiMint")
                .withArgs(addr1.address, hardhat_1.ethers.utils.parseEther("2.5"), hardhat_1.ethers.utils.parseEther("2.5"), hardhat_1.ethers.utils.parseEther("1"));
            (0, chai_1.expect)(await upToken.balanceOf(addr1.address)).equal(hardhat_1.ethers.utils.parseEther("2.5"));
        });
        it("Should mint UP #1", async () => {
            await (0, chai_1.expect)(upMintDarbi.mintUP({ value: hardhat_1.ethers.utils.parseEther("2") }))
                .emit(upMintDarbi, "DarbiMint")
                .withArgs(addr1.address, hardhat_1.ethers.utils.parseEther("5"), hardhat_1.ethers.utils.parseEther("2.5"), hardhat_1.ethers.utils.parseEther("2"));
            (0, chai_1.expect)(await upToken.balanceOf(addr1.address)).equal(hardhat_1.ethers.utils.parseEther("5"));
        });
        it("Should mint UP #2", async () => {
            await (0, chai_1.expect)(upMintDarbi.mintUP({ value: hardhat_1.ethers.utils.parseEther("3") }))
                .emit(upMintDarbi, "DarbiMint")
                .withArgs(addr1.address, hardhat_1.ethers.utils.parseEther("7.5"), hardhat_1.ethers.utils.parseEther("2.5"), hardhat_1.ethers.utils.parseEther("3"));
            (0, chai_1.expect)(await upToken.balanceOf(addr1.address)).equal(hardhat_1.ethers.utils.parseEther("7.5"));
        });
        it("Shouldn't be able to mint UP because no DARBI_ROLE", async () => {
            const [, a2] = await hardhat_1.ethers.getSigners();
            const addr2UpMintDarbi = upMintDarbi.connect(a2);
            await (0, chai_1.expect)(addr2UpMintDarbi.mintUP({ value: hardhat_1.ethers.utils.parseEther("3") })).revertedWith("ONLY_DARBI");
        });
    });
});
