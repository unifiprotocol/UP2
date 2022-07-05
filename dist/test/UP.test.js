"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const hardhat_1 = require("hardhat");
describe("UPv2", function () {
    let upToken;
    let addr1;
    beforeEach(async () => {
        const [a1] = await hardhat_1.ethers.getSigners();
        addr1 = a1;
        upToken = await hardhat_1.ethers
            .getContractFactory("UP")
            .then((factory) => factory.deploy())
            .then((instance) => instance.deployed());
    });
    it("Should assert token basic info", async () => {
        const name = await upToken.name();
        const symbol = await upToken.symbol();
        const decimals = await upToken.decimals();
        const totalSupply = await upToken.totalSupply();
        const adminRoleNS = await upToken.DEFAULT_ADMIN_ROLE();
        (0, chai_1.expect)(name).equal("UP");
        (0, chai_1.expect)(symbol).equal("UP");
        (0, chai_1.expect)(decimals).equal(18);
        (0, chai_1.expect)(totalSupply).equal(0);
        (0, chai_1.expect)(await upToken.hasRole(adminRoleNS, addr1.address)).equal(true);
    });
    it("Should set a new controller address", async () => {
        (0, chai_1.expect)(await upToken.UP_CONTROLLER()).eq(hardhat_1.ethers.constants.AddressZero);
        await upToken.setController(addr1.address);
        (0, chai_1.expect)(await upToken.UP_CONTROLLER()).eq(addr1.address);
    });
    describe("Mint/Burn", () => {
        let upTokenAddr2;
        let addr1;
        let addr2;
        let addr3;
        beforeEach(async () => {
            const [a1, a2, a3] = await hardhat_1.ethers.getSigners();
            upTokenAddr2 = upToken.connect(a2);
            addr1 = a1;
            addr2 = a2;
            addr3 = a3;
        });
        it("Should mint 1 UP", async () => {
            const controllerRoleNS = await upToken.MINT_ROLE();
            await upToken.grantRole(controllerRoleNS, addr2.address);
            await upTokenAddr2.mint(addr2.address, hardhat_1.ethers.constants.WeiPerEther);
            (0, chai_1.expect)(await upTokenAddr2.totalSupply()).equal(hardhat_1.ethers.constants.WeiPerEther);
            (0, chai_1.expect)(await upTokenAddr2.balanceOf(addr2.address)).equal(hardhat_1.ethers.constants.WeiPerEther);
        });
        it("Should mint 1 UP and transfer it", async () => {
            const controllerRoleNS = await upToken.MINT_ROLE();
            await upToken.grantRole(controllerRoleNS, addr2.address);
            await upTokenAddr2.mint(addr2.address, hardhat_1.ethers.constants.WeiPerEther);
            await upTokenAddr2.transfer(addr1.address, hardhat_1.ethers.constants.WeiPerEther);
            (0, chai_1.expect)(await upTokenAddr2.balanceOf(addr1.address)).equal(hardhat_1.ethers.constants.WeiPerEther);
            (0, chai_1.expect)(await upTokenAddr2.balanceOf(addr2.address)).equal(0);
        });
        it("Should mint 1 UP and burn it", async () => {
            const controllerRoleNS = await upToken.MINT_ROLE();
            await upToken.grantRole(controllerRoleNS, addr2.address);
            await upTokenAddr2.mint(addr2.address, hardhat_1.ethers.constants.WeiPerEther);
            (0, chai_1.expect)(await upTokenAddr2.totalSupply()).equal(hardhat_1.ethers.constants.WeiPerEther);
            await upTokenAddr2.burn(hardhat_1.ethers.constants.WeiPerEther);
            (0, chai_1.expect)(await upTokenAddr2.totalSupply()).equal(0);
            (0, chai_1.expect)(await upTokenAddr2.balanceOf(addr2.address)).equal(0);
        });
        it("Should mint 1 UP and burn it using burnFrom", async () => {
            const controllerRoleNS = await upToken.MINT_ROLE();
            await upToken.grantRole(controllerRoleNS, addr2.address);
            await upTokenAddr2.mint(addr2.address, hardhat_1.ethers.constants.WeiPerEther);
            await upTokenAddr2.approve(addr2.address, hardhat_1.ethers.constants.WeiPerEther);
            (0, chai_1.expect)(await upTokenAddr2.allowance(addr2.address, addr2.address)).equal(hardhat_1.ethers.constants.WeiPerEther);
            await upTokenAddr2.burnFrom(addr2.address, hardhat_1.ethers.constants.WeiPerEther);
            (0, chai_1.expect)(await upTokenAddr2.totalSupply()).equal(0);
            (0, chai_1.expect)(await upTokenAddr2.allowance(addr2.address, addr2.address)).equal(0);
            (0, chai_1.expect)(await upTokenAddr2.balanceOf(addr2.address)).equal(0);
        });
        it("Should mint UP and send the value to LEGACY_MINT_ROLE", async () => {
            await upToken.grantRole(await upToken.MINT_ROLE(), addr1.address);
            await upToken.grantRole(await upToken.LEGACY_MINT_ROLE(), addr1.address);
            await upToken.setController(addr3.address);
            const prevBalance = await upToken.provider.getBalance(addr3.address);
            await upToken.mint(addr1.address, hardhat_1.ethers.constants.WeiPerEther, { value: 5 });
            (0, chai_1.expect)(await upToken.provider.getBalance(addr3.address)).equal(prevBalance.add(5));
        });
        it("Should mint UP and send not send native tokens because no controller set", async () => {
            await upToken.grantRole(await upToken.MINT_ROLE(), addr1.address);
            await upToken.grantRole(await upToken.LEGACY_MINT_ROLE(), addr1.address);
            const prevBalance = await upToken.provider.getBalance(addr3.address);
            await upToken.mint(addr1.address, hardhat_1.ethers.constants.WeiPerEther, { value: 5 });
            (0, chai_1.expect)(await upToken.provider.getBalance(addr3.address)).equal(prevBalance);
        });
    });
    describe("AccessControl", () => {
        it("Should grant MINT_ROLE", async () => {
            const [, addr2, addr3] = await hardhat_1.ethers.getSigners();
            const controllerRoleNS = await upToken.MINT_ROLE();
            await upToken.grantRole(controllerRoleNS, addr2.address);
            await upToken.grantRole(controllerRoleNS, addr3.address);
            (0, chai_1.expect)(await upToken.hasRole(controllerRoleNS, addr2.address)).equal(true);
            (0, chai_1.expect)(await upToken.hasRole(controllerRoleNS, addr3.address)).equal(true);
        });
        it("MINT_ROLE should be able to mint tokens", async () => {
            const [, addr2] = await hardhat_1.ethers.getSigners();
            const controllerRoleNS = await upToken.MINT_ROLE();
            await upToken.grantRole(controllerRoleNS, addr2.address);
            const upAddr2 = upToken.connect(addr2);
            await upAddr2.mint(addr2.address, 1);
            (0, chai_1.expect)(await upAddr2.totalSupply()).equal(1);
            (0, chai_1.expect)(await upAddr2.balanceOf(addr2.address)).equal(1);
        });
        it("MINT_ROLE account shouldn't be able to assing roles", async () => {
            const [, addr2, addr3] = await hardhat_1.ethers.getSigners();
            const controllerRoleNS = await upToken.MINT_ROLE();
            await upToken.grantRole(controllerRoleNS, addr2.address);
            const upAddr2 = upToken.connect(addr2);
            await (0, chai_1.expect)(upAddr2.grantRole(controllerRoleNS, addr3.address)).to.be.reverted;
            (0, chai_1.expect)(await upAddr2.getRoleAdmin(controllerRoleNS)).equal(hardhat_1.ethers.constants.HashZero);
        });
        it("ADMIN_ROLE shouldn't be able to mint tokens", async () => {
            const [, addr2] = await hardhat_1.ethers.getSigners();
            await (0, chai_1.expect)(upToken.mint(addr2.address, 1)).revertedWith("ONLY_MINT");
        });
        it("3rd party shouldn't be able to mint tokens", async () => {
            const [, , addr3] = await hardhat_1.ethers.getSigners();
            const upAddr3 = upToken.connect(addr3);
            await (0, chai_1.expect)(upAddr3.mint(addr3.address, 1)).revertedWith("ONLY_MINT");
        });
    });
    describe("Legacy mint logic", () => {
        let upController;
        beforeEach(async () => {
            upController = await hardhat_1.ethers
                .getContractFactory("UPController")
                .then((factory) => factory.deploy(upToken.address))
                .then((instance) => instance.deployed());
            await upToken.grantRole(await upToken.MINT_ROLE(), addr1.address);
            await upToken.grantRole(await upToken.MINT_ROLE(), upController.address);
        });
        it("Should mint based in virtualPrice #0", async () => {
            await addr1.sendTransaction({
                to: upController.address,
                value: hardhat_1.ethers.utils.parseEther("5")
            });
            await upToken.mint(upController.address, hardhat_1.ethers.utils.parseEther("2"));
            await upToken.grantRole(await upToken.LEGACY_MINT_ROLE(), addr1.address);
            await upToken.setController(upController.address);
            await upToken.mint(addr1.address, 0, { value: hardhat_1.ethers.utils.parseEther("5") });
            (0, chai_1.expect)(await upToken.balanceOf(addr1.address)).equal(hardhat_1.ethers.utils.parseEther("12.5"));
        });
        it("Should mint based in virtualPrice #1", async () => {
            await addr1.sendTransaction({
                to: upController.address,
                value: hardhat_1.ethers.utils.parseEther("5")
            });
            await upToken.mint(upController.address, hardhat_1.ethers.utils.parseEther("4"));
            await upToken.grantRole(await upToken.LEGACY_MINT_ROLE(), addr1.address);
            await upToken.setController(upController.address);
            await upToken.mint(addr1.address, 0, { value: hardhat_1.ethers.utils.parseEther("5") });
            (0, chai_1.expect)(await upToken.balanceOf(addr1.address)).equal(hardhat_1.ethers.utils.parseEther("6.25"));
        });
        it("Should forward native balances to UP_CONTROLLER", async () => {
            await upToken.setController(upController.address);
            await addr1.sendTransaction({
                to: upToken.address,
                value: hardhat_1.ethers.utils.parseEther("5")
            });
            (0, chai_1.expect)(await upToken.provider.getBalance(upToken.address)).equal(hardhat_1.ethers.utils.parseEther("5"));
            await upToken.withdrawFunds();
            (0, chai_1.expect)(await upToken.provider.getBalance(upController.address)).equal(hardhat_1.ethers.utils.parseEther("5"));
        });
        it("Should fail forwarding native balances to UP_CONTROLLER because not UP_CONTROLLER", async () => {
            await (0, chai_1.expect)(upToken.withdrawFunds()).to.be.reverted;
        });
    });
});
