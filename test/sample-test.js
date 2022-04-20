const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("UPv2New", function () {
  it("Should return the name & symbol of the token", async function () {
    const UPv2 = await ethers.getContractFactory("UPv2New");
    const upv2 = await UPv2.deploy();
    await upv2.deployed();

    expect(await upv2.name()).to.equal("UPv2");
    expect(await upv2.symbol()).to.equal("UPv2");
    /// Currently Fails
  });
});
