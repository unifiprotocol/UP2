const contractsName = ["WETH", "Router", "Factory"] as const

type ContractName = typeof contractsName[number]

// BSC Testnet uTrade contracts
const contracts: Record<ContractName, string> = {
  Router: "0xBE930734eDAfc41676A76d2240f206Ed36dafbA2",
  Factory: "0xA5Ba037Ec16c45f8ae09e013C1849554C01385f5",
  WETH: "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"
}

export default contracts
