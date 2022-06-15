import { task } from "hardhat/config"
import { FactoryOptions } from "hardhat/types"

export const generateGetterSetter = (
  contractName: string,
  factoryOptions: Omit<FactoryOptions, "libraries"> & {
    libraries?: { [libraryName: string]: any }
  } = {}
) => {
  return task(contractName)
    .addParam("address", "contract contract address")
    .addParam("method", "contract method name")
    .addOptionalParam("args", "Comma separated args")
    .setAction(async ({ address, method, args }, hre) => {
      await hre.run("compile")

      let libraries = {}
      if (factoryOptions.libraries) {
        const network = hre.network.name
        libraries = Object.keys(factoryOptions.libraries).reduce(
          (libs: { [libName: string]: any }, i) => {
            libs[i] = factoryOptions.libraries![i][network]
            return libs
          },
          {}
        )
      }

      const contract = await hre.ethers.getContractFactory(contractName, {
        ...factoryOptions,
        libraries
      })
      const instance = contract.attach(address)

      const parsedArgs = (args ?? "").split(",")

      const result = await (instance as any)[method].apply(parsedArgs)

      console.log("---", method, result)
    })
}
