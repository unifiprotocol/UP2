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
    expect(nameReturn).equal("UPbnb");
    expect(symbolReturn).equal("UPbnb");
    expect(totalSupplyReturn).equal(0);
  });
});
