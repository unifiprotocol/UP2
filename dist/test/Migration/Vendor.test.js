"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const hardhat_1 = require("hardhat");
describe("Vendor", function () {
    let upToken1;
    let upToken2;
    let vendor;
    let addr1;
    beforeEach(async () => {
        const [a1] = await hardhat_1.ethers.getSigners();
        addr1 = a1;
        upToken1 = await hardhat_1.ethers
            .getContractFactory("UP")
            .then((factory) => factory.deploy())
            .then((instance) => instance.deployed());
        upToken2 = await hardhat_1.ethers
            .getContractFactory("UP")
            .then((factory) => factory.deploy())
            .then((instance) => instance.deployed());
        vendor = await hardhat_1.ethers
            .getContractFactory("Vendor")
            .then((factory) => factory.deploy(upToken1.address, upToken2.address))
            .then((instance) => instance.deployed());
        const controllerRoleNS1 = await upToken1.MINT_ROLE();
        const controllerRoleNS2 = await upToken2.MINT_ROLE();
        await upToken1.grantRole(controllerRoleNS1, addr1.address);
        await upToken2.grantRole(controllerRoleNS2, addr1.address);
    });
    it("Should assert contract basic info", async () => {
        await upToken2.mint(vendor.address, hardhat_1.ethers.constants.WeiPerEther);
        (0, chai_1.expect)(await vendor.OLD_UP()).equal(upToken1.address);
        (0, chai_1.expect)(await vendor.UP()).equal(upToken2.address);
        (0, chai_1.expect)(await vendor.balance()).equal(hardhat_1.ethers.constants.WeiPerEther);
        (0, chai_1.expect)(await vendor.owner()).equal(addr1.address);
    });
    it("Should swap 1 OLD UP by 1 UP", async () => {
        await upToken1.mint(addr1.address, hardhat_1.ethers.constants.WeiPerEther);
        await upToken2.mint(vendor.address, hardhat_1.ethers.constants.WeiPerEther);
        (0, chai_1.expect)(await upToken1.balanceOf(vendor.address)).equal(0);
        (0, chai_1.expect)(await upToken2.balanceOf(vendor.address)).equal(hardhat_1.ethers.constants.WeiPerEther);
        await upToken1.approve(vendor.address, hardhat_1.ethers.constants.WeiPerEther);
        await (0, chai_1.expect)(vendor.swap(hardhat_1.ethers.constants.WeiPerEther))
            .to.emit(vendor, "Swap")
            .withArgs(addr1.address, hardhat_1.ethers.constants.WeiPerEther);
        (0, chai_1.expect)(await upToken1.balanceOf(vendor.address)).equal(hardhat_1.ethers.constants.WeiPerEther);
        (0, chai_1.expect)(await upToken2.balanceOf(vendor.address)).equal(0);
    });
    it("Swap should fail because insufficent balances on the contract", async () => {
        await upToken1.mint(addr1.address, hardhat_1.ethers.constants.WeiPerEther);
        await upToken2.mint(vendor.address, hardhat_1.ethers.constants.WeiPerEther.div(2));
        await upToken1.approve(vendor.address, hardhat_1.ethers.constants.WeiPerEther);
        await (0, chai_1.expect)(vendor.swap(hardhat_1.ethers.constants.WeiPerEther)).revertedWith("ERC20: transfer amount exceeds balance");
        (0, chai_1.expect)(await upToken1.balanceOf(vendor.address)).equal(0);
        (0, chai_1.expect)(await upToken2.balanceOf(vendor.address)).equal(hardhat_1.ethers.constants.WeiPerEther.div(2));
    });
    it("Swap should fail because the user has insufficent funds", async () => {
        await upToken2.mint(vendor.address, hardhat_1.ethers.constants.WeiPerEther);
        await upToken1.approve(vendor.address, hardhat_1.ethers.constants.WeiPerEther);
        await (0, chai_1.expect)(vendor.swap(hardhat_1.ethers.constants.WeiPerEther)).revertedWith("ERC20: transfer amount exceeds balance");
        (0, chai_1.expect)(await upToken1.balanceOf(vendor.address)).equal(0);
        (0, chai_1.expect)(await upToken2.balanceOf(vendor.address)).equal(hardhat_1.ethers.constants.WeiPerEther);
    });
    it("Should fail because contract is paused", async () => {
        await upToken1.mint(addr1.address, hardhat_1.ethers.constants.WeiPerEther);
        await upToken2.mint(vendor.address, hardhat_1.ethers.constants.WeiPerEther);
        await upToken1.approve(vendor.address, hardhat_1.ethers.constants.WeiPerEther);
        await vendor.pause();
        await (0, chai_1.expect)(vendor.swap(hardhat_1.ethers.constants.WeiPerEther)).revertedWith("Pausable: paused");
        (0, chai_1.expect)(await upToken1.balanceOf(vendor.address)).equal(0);
        (0, chai_1.expect)(await upToken2.balanceOf(vendor.address)).equal(hardhat_1.ethers.constants.WeiPerEther);
    });
    it("Should swap 1 OLD UP by 1 UP after paused and unpaused", async () => {
        await upToken1.mint(addr1.address, hardhat_1.ethers.constants.WeiPerEther);
        await upToken2.mint(vendor.address, hardhat_1.ethers.constants.WeiPerEther);
        await upToken1.approve(vendor.address, hardhat_1.ethers.constants.WeiPerEther);
        await vendor.pause();
        await (0, chai_1.expect)(vendor.swap(hardhat_1.ethers.constants.WeiPerEther)).revertedWith("Pausable: paused");
        await vendor.unpause();
        await (0, chai_1.expect)(vendor.swap(hardhat_1.ethers.constants.WeiPerEther))
            .to.emit(vendor, "Swap")
            .withArgs(addr1.address, hardhat_1.ethers.constants.WeiPerEther);
        (0, chai_1.expect)(await upToken1.balanceOf(vendor.address)).equal(hardhat_1.ethers.constants.WeiPerEther);
        (0, chai_1.expect)(await upToken2.balanceOf(vendor.address)).equal(0);
    });
    it("Should withdraw 1 UP using withdrawFundsERC20", async () => {
        await upToken2.mint(vendor.address, hardhat_1.ethers.constants.WeiPerEther);
        await vendor.withdrawFundsERC20(addr1.address, upToken2.address);
        (0, chai_1.expect)(await upToken2.balanceOf(vendor.address)).equal(0);
        (0, chai_1.expect)(await upToken2.balanceOf(addr1.address)).equal(hardhat_1.ethers.constants.WeiPerEther);
    });
    it("Should fail withdrawing 1 UP using withdrawFundsERC20 because is not owner", async () => {
        const [, addr2] = await hardhat_1.ethers.getSigners();
        const addr2Vendor = vendor.connect(addr2);
        await upToken2.mint(vendor.address, hardhat_1.ethers.constants.WeiPerEther);
        await (0, chai_1.expect)(addr2Vendor.withdrawFundsERC20(addr2.address, upToken2.address)).revertedWith("Ownable: caller is not the owner");
        (0, chai_1.expect)(await upToken2.balanceOf(vendor.address)).equal(hardhat_1.ethers.constants.WeiPerEther);
        (0, chai_1.expect)(await upToken2.balanceOf(addr2.address)).equal(0);
    });
});
