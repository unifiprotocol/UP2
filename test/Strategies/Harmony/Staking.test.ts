import { BN } from "@unifiprotocol/utils"
import { Signer } from "ethers"
import { ethers } from "hardhat"
import {
  MockedRebalancer,
  MockedUpController,
  TestingHarmonyStakingStrategy
} from "../../../typechain-types"

describe("TestingHarmonyStakingStrategy", function () {
  let signer: Signer
  let stakingContract: TestingHarmonyStakingStrategy
  let mockedRebalancer: MockedRebalancer
  let mockedController: MockedUpController

  beforeEach(async () => {
    const MockedRebalancerCF = await ethers.getContractFactory("MockedRebalancer")
    const MockedUpControllerCF = await ethers.getContractFactory("MockedUpController")
    const TestingHarmonyStakingStrategyCF = await ethers.getContractFactory(
      "TestingHarmonyStakingStrategy"
    )
    const signerAddress = await signer.getAddress()

    mockedRebalancer = await MockedRebalancerCF.deploy(5, 5)
    mockedController = await MockedUpControllerCF.deploy(BN(10).pow(18).toString())
    stakingContract = await TestingHarmonyStakingStrategyCF.deploy(
      signerAddress,
      signerAddress,
      mockedController.address,
      mockedRebalancer.address
    )
  })
})
