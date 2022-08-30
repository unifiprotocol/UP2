import { Signer } from "ethers"
import { ethers } from "hardhat"
import { Rebalancer } from "../../../typechain-types"
import { HarmonyStakingStrategy } from "../../../typechain-types/contracts/Strategies/HarmonyStakingStrategyV2.sol"
import harmonyContracts from "../../Contracts/HarmonyContracts"

describe("HarmonyStaking", () => {
  let REBALANCER: Rebalancer
  let STAKING_STRATEGY: HarmonyStakingStrategy
  let admin: Signer
  beforeEach(async () => {
    const adminAddress = harmonyContracts.MultiSig

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [adminAddress]
    })
    await hre.network.provider.request({
      method: "hardhat_setBalance",
      params: [adminAddress, "0x1000000000000000"]
    })

    admin = await ethers.getSigner(adminAddress)

    STAKING_STRATEGY = await ethers
      .getContractFactory("HarmonyStakingStrategy", admin)
      .then((cf) =>
        cf.deploy(
          adminAddress,
          harmonyContracts.Validator,
          harmonyContracts.UPController,
          harmonyContracts.Rebalancer
        )
      )

    await STAKING_STRATEGY.grantRole(
      await STAKING_STRATEGY.REBALANCER_ROLE(),
      harmonyContracts.Rebalancer
    )

    REBALANCER = await ethers
      .getContractFactory("Rebalancer", {
        signer: admin,
        libraries: {
          UniswapHelper: harmonyContracts.UniswapHelper
        }
      })
      .then((cf) => cf.attach(harmonyContracts.Rebalancer))

    const stakingPrecompiles = await ethers
      .getContractFactory("StakingPrecompiles", admin)
      .then((cf) => cf.deploy())

    await stakingPrecompiles.delegate("0x3bd5c40ddba9aa5f324352993eba00f295b73f34", "0x10000000")

    await hre.network.provider.request({
      method: "hardhat_mine",
      params: ["0x3800c0"]
    })

    await stakingPrecompiles.collectRewards().then((_) => _.data)
  })

  it("Staking strategy is added to Rebalancer and a rebalance is executed correctly", async () => {
    await REBALANCER.setStrategy(STAKING_STRATEGY.address)

    await REBALANCER.rebalance()
  })
})
