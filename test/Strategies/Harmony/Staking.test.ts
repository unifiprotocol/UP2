import { assert, expect } from "chai"
import { Signer } from "ethers"
import { ethers } from "hardhat"
import { TestingHarmonyStakingStrategy } from "../../../typechain-types"

describe("TestingHarmonyStakingStrategy", function () {
  let signer: Signer
  let stakingStrategy: TestingHarmonyStakingStrategy

  beforeEach(async () => {
    const [_signer, _upController] = await ethers.getSigners()
    signer = _signer
    const signerAddress = await signer.getAddress()
    stakingStrategy = await ethers
      .getContractFactory("TestingHarmonyStakingStrategy")
      .then((cf) => cf.deploy(signerAddress, signerAddress, signerAddress, signerAddress))
  })

  describe("gather", async function () {})
})
