const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("UPv2", function () {
  it("Should return the name of the token", async function () {
    const UPv2 = await ethers.getContractFactory("UPv2");
    const upv2 = await UPv2.deploy(16, "UPv2");
    await upv2.deployed();

    expect(await upv2.name()).to.equal("UPv2");
  });
  it("Should return the symbol of the token", async function () {
    const UPv2 = await ethers.getContractFactory("UPv2");
    const upv2 = await UPv2.deploy(16, "UPv2");
    await upv2.deployed();

    expect(await upv2.symbol()).to.equal("UPv2");
  });
});
