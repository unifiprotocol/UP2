"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const chai_1 = require("chai");
const hardhat_1 = require("hardhat");
describe("UPController", function () {
    let upToken;
    let upController;
    let addr1;
    beforeEach(async () => {
        const [a1] = await hardhat_1.ethers.getSigners();
        addr1 = a1;
        upToken = await hardhat_1.ethers
            .getContractFactory("UP")
            .then((factory) => factory.deploy())
            .then((instance) => instance.deployed());
        await upToken.grantRole(await upToken.MINT_ROLE(), addr1.address);
        upController = await hardhat_1.ethers
            .getContractFactory("UPController")
            .then((factory) => factory.deploy(upToken.address))
            .then((instance) => instance.deployed());
        await upToken.grantRole(await upToken.MINT_ROLE(), upController.address);
        await upController.grantRole(await upController.REBALANCER_ROLE(), addr1.address);
    });
    it("Should assert contract basic info", async () => {
        (0, chai_1.expect)(await upController.UP_TOKEN()).equal(upToken.address);
        (0, chai_1.expect)(await upController.nativeBorrowed()).equal(0);
        (0, chai_1.expect)(await upController.upBorrowed()).equal(0);
        (0, chai_1.expect)(await upController.getNativeBalance()).equal(0);
        (0, chai_1.expect)(await upController["getVirtualPrice()"]()).equal(0);
    });
    it("Should change native balance after send funds", async () => {
        await addr1.sendTransaction({
            to: upController.address,
            value: hardhat_1.ethers.utils.parseEther("1")
        });
        (0, chai_1.expect)(await upController.getNativeBalance()).equal(hardhat_1.ethers.utils.parseEther("1"));
    });
    it("Should change virtualPrice after minting and depositing ETH+UP tokens", async () => {
        await addr1.sendTransaction({
            to: upController.address,
            value: hardhat_1.ethers.utils.parseEther("5")
        });
        (0, chai_1.expect)(await upController.getNativeBalance()).equal(hardhat_1.ethers.utils.parseEther("5"));
        await upToken.mint(upController.address, hardhat_1.ethers.utils.parseEther("2"));
        (0, chai_1.expect)(await upController.actualTotalSupply()).equal(hardhat_1.ethers.utils.parseEther("2"));
        (0, chai_1.expect)(await upController["getVirtualPrice()"]()).equal(hardhat_1.ethers.utils.parseEther("2.5"));
    });
    it("Should fail calling mintUP because is not UP_TOKEN the caller", async () => {
        await (0, chai_1.expect)(upController.mintUP(addr1.address)).revertedWith("NON_UP_CONTRACT");
    });
    describe("Borrow", () => {
        describe("borrowNative", () => {
            it("Should borrow native funds and update nativeBorrowed", async () => {
                await addr1.sendTransaction({
                    to: upController.address,
                    value: hardhat_1.ethers.utils.parseEther("5")
                });
                await (0, chai_1.expect)(upController.borrowNative(hardhat_1.ethers.utils.parseEther("3"), addr1.address))
                    .to.emit(upController, "BorrowNative")
                    .withArgs(addr1.address, hardhat_1.ethers.utils.parseEther("3"), hardhat_1.ethers.utils.parseEther("3"));
                (0, chai_1.expect)(await upController.nativeBorrowed()).equal(hardhat_1.ethers.utils.parseEther("3"));
                (0, chai_1.expect)(await upController.getNativeBalance()).equal(hardhat_1.ethers.utils.parseEther("5"));
                (0, chai_1.expect)(await upController.provider.getBalance(upController.address)).equal(hardhat_1.ethers.utils.parseEther("2"));
            });
            it("Should fail borrowing native tokens because there is not enough balances", async () => {
                await addr1.sendTransaction({
                    to: upController.address,
                    value: hardhat_1.ethers.utils.parseEther("4")
                });
                await (0, chai_1.expect)(upController.borrowNative(hardhat_1.ethers.utils.parseEther("6"), addr1.address)).revertedWith("NOT_ENOUGH_BALANCE");
            });
            it("Should fail borrowing native tokens because is not owner", async () => {
                const [, addr2] = await hardhat_1.ethers.getSigners();
                const addr2UpController = upController.connect(addr2);
                await (0, chai_1.expect)(addr2UpController.borrowNative(hardhat_1.ethers.utils.parseEther("6"), addr1.address)).revertedWith("ONLY_REBALANCER");
            });
        });
        describe("borrowUP", () => {
            it("Should borrow UP funds and update upBorrowed", async () => {
                await (0, chai_1.expect)(upController.borrowUP(hardhat_1.ethers.utils.parseEther("3"), addr1.address))
                    .to.emit(upController, "SyntheticMint")
                    .withArgs(addr1.address, hardhat_1.ethers.utils.parseEther("3"), hardhat_1.ethers.utils.parseEther("3"));
                (0, chai_1.expect)(await upController.upBorrowed()).equal(hardhat_1.ethers.utils.parseEther("3"));
                (0, chai_1.expect)(await upController.actualTotalSupply()).equal(hardhat_1.ethers.utils.parseEther("0"));
                (0, chai_1.expect)(await upToken.totalSupply()).equal(hardhat_1.ethers.utils.parseEther("3"));
                (0, chai_1.expect)(await upToken.balanceOf(addr1.address)).equal(hardhat_1.ethers.utils.parseEther("3"));
            });
            it("Should fail borrowing UP tokens because is not owner", async () => {
                const [, addr2] = await hardhat_1.ethers.getSigners();
                const addr2UpController = upController.connect(addr2);
                await (0, chai_1.expect)(addr2UpController.borrowUP(hardhat_1.ethers.utils.parseEther("6"), addr1.address)).revertedWith("ONLY_REBALANCER");
            });
        });
        describe("repay", () => {
            it("Should repay borrowed UP and restore the borrowed count to zero", async () => {
                await upController.borrowUP(hardhat_1.ethers.utils.parseEther("3"), addr1.address);
                await upToken.approve(upController.address, hardhat_1.ethers.utils.parseEther("3"));
                await (0, chai_1.expect)(upController.repay(hardhat_1.ethers.utils.parseEther("3")))
                    .to.emit(upController, "Repay")
                    .withArgs(0, hardhat_1.ethers.utils.parseEther("3"));
                (0, chai_1.expect)(await upController.upBorrowed()).equal(hardhat_1.ethers.utils.parseEther("0"));
            });
            it("Should repay borrowed native and restore the borrowed count to zero", async () => {
                await addr1.sendTransaction({
                    to: upController.address,
                    value: hardhat_1.ethers.utils.parseEther("4")
                });
                await upController.borrowNative(hardhat_1.ethers.utils.parseEther("4"), addr1.address);
                await (0, chai_1.expect)(upController.repay(0, { value: hardhat_1.ethers.utils.parseEther("4") }))
                    .to.emit(upController, "Repay")
                    .withArgs(hardhat_1.ethers.utils.parseEther("4"), 0);
                (0, chai_1.expect)(await upController.nativeBorrowed()).equal(hardhat_1.ethers.utils.parseEther("0"));
            });
            it("Should repay borrowed native and borrowed UP and restore the borrowed count to zero", async () => {
                await addr1.sendTransaction({
                    to: upController.address,
                    value: hardhat_1.ethers.utils.parseEther("4")
                });
                await upController.borrowNative(hardhat_1.ethers.utils.parseEther("4"), addr1.address);
                await upController.borrowUP(hardhat_1.ethers.utils.parseEther("3"), addr1.address);
                await upToken.approve(upController.address, hardhat_1.ethers.utils.parseEther("3"));
                await (0, chai_1.expect)(upController.repay(hardhat_1.ethers.utils.parseEther("3"), { value: hardhat_1.ethers.utils.parseEther("4") }))
                    .to.emit(upController, "Repay")
                    .withArgs(hardhat_1.ethers.utils.parseEther("4"), hardhat_1.ethers.utils.parseEther("3"));
                (0, chai_1.expect)(await upController.nativeBorrowed()).equal(hardhat_1.ethers.utils.parseEther("0"));
                (0, chai_1.expect)(await upController.upBorrowed()).equal(hardhat_1.ethers.utils.parseEther("0"));
            });
            it("Should fail repaying native tokens because amount is higher than the borrowed", async () => {
                await addr1.sendTransaction({
                    to: upController.address,
                    value: hardhat_1.ethers.utils.parseEther("4")
                });
                await upController.borrowNative(hardhat_1.ethers.utils.parseEther("4"), addr1.address);
                await (0, chai_1.expect)(upController.repay(0, { value: hardhat_1.ethers.utils.parseEther("5") })).revertedWith("NATIVE_AMOUNT_GT_BORROWED");
                (0, chai_1.expect)(await upController.nativeBorrowed()).equal(hardhat_1.ethers.utils.parseEther("4"));
            });
            it("Should fail repaying UP tokens because amount is higher than the borrowed", async () => {
                await upController.borrowUP(hardhat_1.ethers.utils.parseEther("3"), addr1.address);
                await upToken.approve(upController.address, hardhat_1.ethers.utils.parseEther("3"));
                await (0, chai_1.expect)(upController.repay(hardhat_1.ethers.utils.parseEther("4"))).revertedWith("UP_AMOUNT_GT_BORROWED");
                (0, chai_1.expect)(await upController.upBorrowed()).equal(hardhat_1.ethers.utils.parseEther("3"));
            });
            it("Should fail repaying tokens because is not owner", async () => {
                const [, addr2] = await hardhat_1.ethers.getSigners();
                const addr2UpController = upController.connect(addr2);
                await (0, chai_1.expect)(addr2UpController.repay(hardhat_1.ethers.utils.parseEther("6"))).revertedWith("ONLY_REBALANCER");
            });
        });
        describe("Redeem", () => {
            let addr2;
            let addr2UpController;
            let addr2UpToken;
            beforeEach(async () => {
                const [, a2] = await hardhat_1.ethers.getSigners();
                addr2 = a2;
                await upController.grantRole(await upController.REDEEMER_ROLE(), addr2.address);
                addr2UpController = upController.connect(addr2);
                addr2UpToken = upToken.connect(addr2);
            });
            it("Should redeem UP by native tokens", async () => {
                await addr1.sendTransaction({
                    to: upController.address,
                    value: hardhat_1.ethers.utils.parseEther("5")
                });
                await upToken.mint(upController.address, hardhat_1.ethers.utils.parseEther("2"));
                await upToken.mint(addr2.address, hardhat_1.ethers.utils.parseEther("2"));
                (0, chai_1.expect)(await upToken.totalSupply()).equal(hardhat_1.ethers.utils.parseEther("4"));
                await addr2UpToken.approve(upController.address, hardhat_1.ethers.utils.parseEther("2"));
                await (0, chai_1.expect)(addr2UpController.redeem(hardhat_1.ethers.utils.parseEther("2")))
                    .to.emit(upController, "Redeem")
                    .withArgs(hardhat_1.ethers.utils.parseEther("2"), hardhat_1.ethers.utils.parseEther("2.5"));
                (0, chai_1.expect)(await upToken.totalSupply()).equal(hardhat_1.ethers.utils.parseEther("2"));
            });
            it("Should fail because redeem amount is zero", async () => {
                await (0, chai_1.expect)(addr2UpController.redeem(hardhat_1.ethers.utils.parseEther("0"))).revertedWith("AMOUNT_EQ_0");
            });
            it("Should fail because not enough UP balance", async () => {
                await addr1.sendTransaction({
                    to: upController.address,
                    value: hardhat_1.ethers.utils.parseEther("5")
                });
                await upToken.mint(upController.address, hardhat_1.ethers.utils.parseEther("2"));
                await upToken.mint(addr2.address, hardhat_1.ethers.utils.parseEther("2"));
                await addr2UpToken.approve(upController.address, hardhat_1.ethers.utils.parseEther("3"));
                await (0, chai_1.expect)(addr2UpController.redeem(hardhat_1.ethers.utils.parseEther("3"))).revertedWith("ERC20: burn amount exceeds balance");
            });
            it("Should fail invoker is not REDEEMER_ROLE", async () => {
                await addr1.sendTransaction({
                    to: upController.address,
                    value: hardhat_1.ethers.utils.parseEther("5")
                });
                await upToken.mint(addr2.address, hardhat_1.ethers.utils.parseEther("2"));
                await upController.revokeRole(await upController.REDEEMER_ROLE(), addr2.address);
                await (0, chai_1.expect)(upController.redeem(hardhat_1.ethers.utils.parseEther("0"))).revertedWith("ONLY_REDEEMER");
            });
        });
    });
    describe("WithdrawFunds", () => {
        it("Should withdraw 1 UP using withdrawFundsERC20", async () => {
            await upToken.mint(upController.address, hardhat_1.ethers.constants.WeiPerEther);
            await upController.withdrawFundsERC20(addr1.address, upToken.address);
            (0, chai_1.expect)(await upToken.balanceOf(upController.address)).equal(0);
            (0, chai_1.expect)(await upToken.balanceOf(addr1.address)).equal(hardhat_1.ethers.constants.WeiPerEther);
        });
        it("Should withdraw 1 ETH using withdrawFunds", async () => {
            await addr1.sendTransaction({
                to: upController.address,
                value: hardhat_1.ethers.constants.WeiPerEther
            });
            (0, chai_1.expect)(await upController.provider.getBalance(upController.address)).equal(hardhat_1.ethers.constants.WeiPerEther);
            await upController.withdrawFunds(addr1.address);
            (0, chai_1.expect)(await upController.provider.getBalance(upController.address)).equal(0);
        });
        it("Should fail withdrawing 1 UP using withdrawFundsERC20 because is not owner", async () => {
            const [, addr2] = await hardhat_1.ethers.getSigners();
            const addr2upController = upController.connect(addr2);
            await upToken.mint(upController.address, hardhat_1.ethers.constants.WeiPerEther);
            await (0, chai_1.expect)(addr2upController.withdrawFundsERC20(addr2.address, upToken.address)).revertedWith("ONLY_ADMIN");
            (0, chai_1.expect)(await upToken.balanceOf(upController.address)).equal(hardhat_1.ethers.constants.WeiPerEther);
            (0, chai_1.expect)(await upToken.balanceOf(addr2.address)).equal(0);
        });
    });
});
