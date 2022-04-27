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
    expect(totalSupplyReturn).equal(0);
    expect(darbiAddressReturn).equal(
      "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
    );
  });

  it("Should mint UP", async function () {
    const UPbnb = await ethers.getContractFactory("UPbnb");
    const upbnb = await UPbnb.deploy();
    await upbnb.deployed();
    const [signer, second, third] = await ethers.getSigners();
    const signerAddress = await signer.getAddress();
    const secondAddress = await second.getAddress();
    const thirdAddress = await third.getAddress();
    const upAddress = await upbnb.address;
    const one = ethers.utils.parseEther("1");
    const two = ethers.utils.parseEther("2");
    console.log(upAddress);
    const upBalanceBefore = await ethers.provider.getBalance(upAddress);
    expect(upBalanceBefore).equal(0);
    const fundingTX = await second.sendTransaction({
      to: upAddress,
      value: ethers.utils.parseEther("1.0"), // Sends exactly 1.0 ether
    });
    const upBalanceAfterOne = await ethers.provider.getBalance(upAddress);
    expect(upBalanceAfterOne).equal(one);
    // const publicMintTX = await upbnb
    //   .connect(third)
    //   .publicMint(thirdAddress, one, { value: one });
    // const upBalanceAfterTwo = await ethers.provider.getBalance(upAddress);
    // expect(upBalanceAfterTwo).equal(two);
  });
});
