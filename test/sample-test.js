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
    console.log("Total Supply Equals 1 on Deploy");
    const nativeTotalBefore = await upbnb.getNativeTotal();
    expect(nativeTotalBefore).equal(0);
    console.log("Native Tokens Equals 0 on Deploy");
    const redeemValueBefore = await upbnb.getVirtualPrice();
    expect(redeemValueBefore).equal(0);
    console.log("Redeem Value Equals 0 on Deploy");
    const upAddress = await upbnb.address;
    await signer.sendTransaction({ to: upAddress, value: one });
    const totalSupplyAfter = await upbnb.totalSupply();
    expect(totalSupplyAfter).equal(one);
    console.log("Total Supply Equals 1 on After Funding");
    const nativeTotalAfter = await upbnb.getNativeTotal();
    expect(nativeTotalAfter).equal(one);
    console.log("Native Tokens Equals 1 on After Funding");
    const redeemValueAfter = await upbnb.getVirtualPrice();
    expect(redeemValueAfter).equal(one);
    console.log("Redeem Value Equals 1 on After Funding");
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
    console.log("Total Supply Equals 1 on Deploy");
    const getUpMintedSigner = await upbnb.balanceOf(signerAddress);
    expect(getUpMintedSigner).equal(ethers.utils.parseEther("1"));
    console.log("Signer has 1 UP");
    const nativeTotalBefore = await upbnb.getNativeTotal();
    expect(nativeTotalBefore).equal(0);
    console.log("Native Tokens Equals 0 on Deploy");
    const redeemValueBefore = await upbnb.getVirtualPrice();
    expect(redeemValueBefore).equal(0);
    console.log("Redeem Value Equals 0 on Deploy");
    const upAddress = await upbnb.address;
    await signer.sendTransaction({ to: upAddress, value: one });
    const totalSupplyAfter = await upbnb.totalSupply();
    expect(totalSupplyAfter).equal(one);
    console.log("Total Supply Equals 1 on After Funding");
    const nativeTotalAfter = await upbnb.getNativeTotal();
    expect(nativeTotalAfter).equal(one);
    console.log("Native Tokens Equals 1 on After Funding");
    const redeemValueAfter = await upbnb.getVirtualPrice();
    expect(redeemValueAfter).equal(one);
    console.log("Redeem Value Equals 1 on After Funding");
    await upbnb.connect(second).publicMint(secondAddress, one, { value: one });
    const totalSupplyAfterMint = await upbnb.totalSupply();
    expect(totalSupplyAfterMint).equal(ethers.utils.parseEther("1.95"));
    console.log("Total Supply Equals 1.95 After Public Mint");
    const nativeTotalAfterMint = await upbnb.getNativeTotal();
    expect(nativeTotalAfterMint).equal(ethers.utils.parseEther("2"));
    console.log("Native Tokens Equals 2 After Public Mint");
    const redeemValueAfterMint = await upbnb.getVirtualPrice();
    expect(redeemValueAfterMint).equal(
      ethers.utils.parseEther("1.025641025641025641")
    );
    console.log("Redeem Value equals 1.025641025641025641 After Public Mint");
    const getUpMintedSecond = await upbnb.balanceOf(secondAddress);
    expect(getUpMintedSecond).equal(ethers.utils.parseEther("0.95"));
    console.log("Public Minted has 0.95 UP");
  });
});
