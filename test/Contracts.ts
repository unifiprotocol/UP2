const contractsName = ["WETH", "Router", "Factory"] as const

type ContractName = typeof contractsName[number]

// BSC Testnet uTrade contracts
const contracts: Record<ContractName, string> = {
  Router: "0x8E07E90f7F5AD5EBaCCE04f020BD08D7572BB36E",
  Factory: "0xcAF0DFf51989Cee8f6437A7152001A42116170d5",
  WETH: "0xC578c6e2505Fd2B227A64350ABf85e7221D17c91"
}

export default contracts
