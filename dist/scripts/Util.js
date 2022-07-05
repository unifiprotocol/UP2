"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateGetterSetter = void 0;
const config_1 = require("hardhat/config");
const generateGetterSetter = (contractName, factoryOptions = {}) => {
    return (0, config_1.task)(contractName)
        .addParam("address", "contract contract address")
        .addParam("method", "contract method name")
        .addOptionalParam("args", "Comma separated args")
        .setAction(async ({ address, method, args }, hre) => {
        await hre.run("compile");
        let libraries = {};
        if (factoryOptions.libraries) {
            const network = hre.network.name;
            libraries = Object.keys(factoryOptions.libraries).reduce((libs, i) => {
                libs[i] = factoryOptions.libraries[i][network];
                return libs;
            }, {});
        }
        const contract = await hre.ethers.getContractFactory(contractName, {
            ...factoryOptions,
            libraries
        });
        const instance = contract.attach(address);
        const parsedArgs = (args !== null && args !== void 0 ? args : "").split(",");
        const result = await instance[method].apply(parsedArgs);
        console.log("---", method, result);
    });
};
exports.generateGetterSetter = generateGetterSetter;
