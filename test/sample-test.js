const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("UPbnb", function () {
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

  it("Should deploy with a supply of 1 UP, receive a transaction worth 1 ETH, update redeem value", async function () {
    const UPbnb = await ethers.getContractFactory("UPbnb");
    const upbnb = await UPbnb.deploy();
    await upbnb.deployed();
    const [signer, second, third] = await ethers.getSigners();
    const signerAddress = await signer.getAddress();
    const secondAddress = await second.getAddress();
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
    const fundingTX = await second.sendTransaction({
      to: upAddress,
      value: one,
    });
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

  // it("Should mint UP", async function () {
  //   const UPbnb = await ethers.getContractFactory("UPbnb");
  //   const upbnb = await UPbnb.deploy();
  //   await upbnb.deployed();
  //   const [signer, second, third] = await ethers.getSigners();
  //   const signerAddress = await signer.getAddress();
  //   const secondAddress = await second.getAddress();
  //   const thirdAddress = await third.getAddress();
  //   const upAddress = await upbnb.address;
  //   const one = ethers.utils.parseEther("1");
  //   console.log(upAddress);
  //   const upETHBalanceBefore = await ethers.provider.getBalance(upAddress);
  //   expect(upETHBalanceBefore).equal(0);

  //   const fundingTX = await second.sendTransaction({
  //     to: upAddress,
  //     value: ethers.utils.parseEther("1.0"), // Sends exactly 1.0 ether
  //   });
  //   const upBalanceAfterOne = await ethers.provider.getBalance(upAddress);
  //   expect(upBalanceAfterOne).equal(one);
  //   console.log(secondAddress);
  //   // const publicMintTX = await upbnb
  //   .connect(third)
  //   .publicMint(thirdAddress, one, { value: one });
  // const upBalanceAfterTwo = await ethers.provider.getBalance(upAddress);
  // expect(upBalanceAfterTwo).equal(two);
  // });
});
