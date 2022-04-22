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
});
