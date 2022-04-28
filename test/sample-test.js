const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("UPbnb Parameters", function () {
  it("Should return the name & symbol of the token", async function () {
    const UPbnb = await ethers.getContractFactory("UPbnb");
    const upbnb = await UPbnb.deploy();
    await upbnb.deployed();
    const nameReturn = await upbnb.name();
    const symbolReturn = await upbnb.symbol();
    const totalSupplyReturn = await upbnb.totalSupply();
    const darbiAddressReturn = await upbnb.darbiAddress();
    expect(nameReturn).equal("UPbnb");
    expect(symbolReturn).equal("UPbnb");
    expect(totalSupplyReturn).equal(ethers.utils.parseEther("1"));
    expect(darbiAddressReturn).equal(
      "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
    );
  });
});

describe("UPbnb UP Minting", function () {
  it("Should deploy with a supply of 1 UP, receive a transaction worth 1 ETH, update redeem value", async function () {
    const UPbnb = await ethers.getContractFactory("UPbnb");
    const upbnb = await UPbnb.deploy();
    await upbnb.deployed();
    const [signer] = await ethers.getSigners();
    const totalSupplyBefore = await upbnb.totalSupply();
    const one = ethers.utils.parseEther("1");
    expect(totalSupplyBefore).equal(one);
    const nativeTotalBefore = await upbnb.getNativeTotal();
    expect(nativeTotalBefore).equal(0);
    const redeemValueBefore = await upbnb.getVirtualPrice();
    expect(redeemValueBefore).equal(0);
    const upAddress = await upbnb.address;
    await signer.sendTransaction({ to: upAddress, value: one });
    const totalSupplyAfter = await upbnb.totalSupply();
    expect(totalSupplyAfter).equal(one);
    const nativeTotalAfter = await upbnb.getNativeTotal();
    expect(nativeTotalAfter).equal(one);
    const redeemValueAfter = await upbnb.getVirtualPrice();
    expect(redeemValueAfter).equal(one);
  });

  it("Should publically mint UP", async function () {
    const UPbnb = await ethers.getContractFactory("UPbnb");
    const upbnb = await UPbnb.deploy();
    await upbnb.deployed();
    const [signer, second] = await ethers.getSigners();
    const signerAddress = await signer.getAddress();
    const secondAddress = await second.getAddress();
    const totalSupplyBefore = await upbnb.totalSupply();
    const one = ethers.utils.parseEther("1");
    expect(totalSupplyBefore).equal(one);
    const getUpMintedSigner = await upbnb.balanceOf(signerAddress);
    expect(getUpMintedSigner).equal(ethers.utils.parseEther("1"));
    const nativeTotalBefore = await upbnb.getNativeTotal();
    expect(nativeTotalBefore).equal(0);
    const redeemValueBefore = await upbnb.getVirtualPrice();
    expect(redeemValueBefore).equal(0);
    const upAddress = await upbnb.address;
    await signer.sendTransaction({ to: upAddress, value: one });
    const totalSupplyAfter = await upbnb.totalSupply();
    expect(totalSupplyAfter).equal(one);
    const nativeTotalAfter = await upbnb.getNativeTotal();
    expect(nativeTotalAfter).equal(one);
    const redeemValueAfter = await upbnb.getVirtualPrice();
    expect(redeemValueAfter).equal(one);
    await upbnb.connect(second).publicMint(secondAddress, one, { value: one });
    const totalSupplyAfterMint = await upbnb.totalSupply();
    expect(totalSupplyAfterMint).equal(ethers.utils.parseEther("1.95"));
    const nativeTotalAfterMint = await upbnb.getNativeTotal();
    expect(nativeTotalAfterMint).equal(ethers.utils.parseEther("2"));
    const redeemValueAfterMint = await upbnb.getVirtualPrice();
    expect(redeemValueAfterMint).equal(
      ethers.utils.parseEther("1.025641025641025641")
    );
    const getUpMintedSecond = await upbnb.balanceOf(secondAddress);
    expect(getUpMintedSecond).equal(ethers.utils.parseEther("0.95"));
  });
});
