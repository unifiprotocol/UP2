const contractsName = [
  "WETH",
  "Router",
  "Factory",
  "Rebalancer",
  "Darbi",
  "Validator",
  "UPController",
  "MultiSig",
  "UniswapHelper"
] as const

type ContractName = typeof contractsName[number]

// BSC Testnet uTrade contracts
const harmonyContracts: Record<ContractName, string> = {
  Router: "0xbFD48577e368322966CfdA94c0A63078ce2F0402",
  Factory: "0x7aB6ef0cE51a2aDc5B673Bad7218C01AE9B04695",
  WETH: "0xcf664087a5bb0237a0bad6742852ec6c8d69a27a",
  Rebalancer: "0xA79192ca5CcE06212197dD9d681E964009Cb6C1B",
  MultiSig: "0xb6f988ddf7F3eF18546FD277b8038AcB402FAA77",
  Darbi: "0x6af04E3BeEB895eb46426c568b4ad140958d2f95",
  Validator: "0x3bd5c40ddba9aa5f324352993eba00f295b73f34",
  UPController: "0x10f51622a7A83B57BA77E40B6f8d598C89ACd045",
  UniswapHelper: "0xef8b8a510be77835c41ffc07958db0f273d740a5"
}

export default harmonyContracts
