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
    expect(MINTER_ROLE).equal("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266");
  });
});
