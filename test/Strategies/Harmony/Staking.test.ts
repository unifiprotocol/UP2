import { BN } from "@unifiprotocol/utils"
import { expect } from "chai"
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
    const [_signer] = await ethers.getSigners()
    signer = _signer
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

  describe("afterDelegate", async () => {
    it("should update attributes correctly", async () => {
      const STAKED_AMOUNT = BN(10).pow(18).toString()

      await stakingContract.setTestingConditions(0, STAKED_AMOUNT, 0, 0)

      const prevAmountDeposited = await stakingContract.amountDeposited()

      expect(await stakingContract.amountStaked()).to.be.equal(
        STAKED_AMOUNT,
        `staked amount should be ${STAKED_AMOUNT}`
      )

      expect(prevAmountDeposited.toString()).to.be.equal(STAKED_AMOUNT)

      await stakingContract.afterDelegate(STAKED_AMOUNT)

      const postAmountDeposited = await stakingContract.amountDeposited()

      const postStakedAmount = await stakingContract.amountStaked()

      expect(postStakedAmount).to.be.equal(BN(STAKED_AMOUNT).times(2).toString())

      expect(postStakedAmount).to.be.equal(
        postAmountDeposited.toString(),
        "Deposited amount should be equal to staked amount"
      )
    })

    it("should update attributes correctly", async () => {
      const STAKED_AMOUNT = BN(10).pow(18).toString()

      await stakingContract.setTestingConditions(0, STAKED_AMOUNT, 0, 0)

      const prevAmountDeposited = await stakingContract.amountDeposited()

      expect(await stakingContract.amountStaked()).to.be.equal(
        STAKED_AMOUNT,
        `staked amount should be ${STAKED_AMOUNT}`
      )

      expect(prevAmountDeposited.toString()).to.be.equal(STAKED_AMOUNT)

      await stakingContract.afterDelegate(STAKED_AMOUNT)

      const postAmountDeposited = await stakingContract.amountDeposited()

      const postStakedAmount = await stakingContract.amountStaked()

      expect(postStakedAmount).to.be.equal(BN(STAKED_AMOUNT).times(2).toString())

      expect(postStakedAmount).to.be.equal(
        postAmountDeposited.toString(),
        "Deposited amount should be equal to staked amount"
      )
    })
  })

  describe("afterUndelegate", async () => {
    it("should update attributes", async () => {
      const STAKED_AMOUNT = BN(10).pow(18).toString()
      const UNSTAKE_AMOUNT = BN(STAKED_AMOUNT).div(2).toString()
      await stakingContract.setTestingConditions(0, STAKED_AMOUNT, 0, 0)

      const prevStakedAmount = await stakingContract.amountStaked()
      const prevDepositedAmount = await stakingContract.amountDeposited()
      const prevPendingDelegation = await stakingContract.pendingUndelegation()

      expect(prevStakedAmount).to.be.equals(STAKED_AMOUNT)
      expect(prevDepositedAmount).to.be.equals(STAKED_AMOUNT)
      expect(prevPendingDelegation).to.be.equals(0)

      await stakingContract.afterUndelegate(UNSTAKE_AMOUNT)

      const postStakedAmount = await stakingContract.amountStaked()
      const postDepositedAmount = await stakingContract.amountDeposited()
      const postPendingDelegation = await stakingContract.pendingUndelegation()

      expect(postStakedAmount).to.be.equals(prevStakedAmount.sub(UNSTAKE_AMOUNT))
      expect(postDepositedAmount).to.be.equals(prevDepositedAmount)
      expect(postPendingDelegation).to.be.equals(UNSTAKE_AMOUNT)
    })

    it("should fail due to too high amount to unstake ", async () => {
      const STAKED_AMOUNT = BN(10).pow(18).toString()
      const UNSTAKE_AMOUNT = BN(STAKED_AMOUNT).times(2).toString()
      await stakingContract.setTestingConditions(0, STAKED_AMOUNT, 0, 0)

      const prevStakedAmount = await stakingContract.amountStaked()
      const prevDepositedAmount = await stakingContract.amountDeposited()
      const prevPendingDelegation = await stakingContract.pendingUndelegation()

      expect(prevStakedAmount).to.be.equals(STAKED_AMOUNT)
      expect(prevDepositedAmount).to.be.equals(STAKED_AMOUNT)
      expect(prevPendingDelegation).to.be.equals(0)

      await expect(stakingContract.afterUndelegate(UNSTAKE_AMOUNT)).to.be.reverted
    })
  })

  describe("afterGather", async () => {
    it("should update attributes and transfer lastClaimedAmount", async () => {
      const AMOUNT_TO_CLAIM = BN(10).pow(18).toString()
      const EPOCH = 10
      await stakingContract.setTestingConditions(AMOUNT_TO_CLAIM, 0, 100, AMOUNT_TO_CLAIM, {
        value: AMOUNT_TO_CLAIM
      })

      const prevBalance = await ethers.provider.getBalance(await signer.getAddress())

      expect(await stakingContract.pendingUndelegation()).not.to.be.equal(
        0,
        "pendingUndelegation shouldn't be zero"
      )
      expect(await stakingContract.epochOfLastRebalance()).not.to.be.equal(
        EPOCH,
        `epochOfLastRebalance shouldn't be ${EPOCH}`
      )
      expect(await ethers.provider.getBalance(stakingContract.address)).to.be.equal(
        AMOUNT_TO_CLAIM,
        `contract balance should be ${AMOUNT_TO_CLAIM}`
      )

      const { wait, gasPrice } = await stakingContract.afterGather(EPOCH)

      const { gasUsed, blockNumber } = await wait()
      const { timestamp } = await ethers.provider.getBlock(blockNumber)

      const postBalance = await ethers.provider.getBalance(await signer.getAddress())

      expect(await stakingContract.epochOfLastRebalance()).to.be.equal(
        EPOCH,
        "epoch should have been updated"
      )
      expect(await stakingContract.pendingUndelegation()).to.be.equal(
        0,
        "pendingUndelegation should have been updated to 0"
      )
      expect(await stakingContract.timestampOfLastClaim()).to.be.equal(timestamp)
      expect(prevBalance.add(AMOUNT_TO_CLAIM).sub(gasUsed.mul(gasPrice!))).to.be.equal(postBalance)
    })

    it("should fail due to unsufficient balance", async () => {
      const AMOUNT_TO_CLAIM = BN(10).pow(18).toString()
      const TARGET_BALANCE = BN(AMOUNT_TO_CLAIM).div(2).toString()
      const EPOCH = 10

      await stakingContract.setTestingConditions(TARGET_BALANCE, 0, 100, AMOUNT_TO_CLAIM, {
        value: TARGET_BALANCE
      })

      await expect(stakingContract.afterGather(EPOCH)).to.be.revertedWith("FAIL_SENDING_NATIVE")
    })
  })

  describe("afterUndelegateAll", async () => {
    it("should update attributes", async () => {
      const STAKED_AMOUNT = BN(10).pow(18).toString()
      const TARGET_EPOCH = 100
      await stakingContract.setTestingConditions(0, STAKED_AMOUNT, 0, 0)

      const prevStakeAmount = await stakingContract.amountStaked()
      const prevLastRebalanceEpoch = await stakingContract.epochOfLastRebalance()
      const prevPendingUndelegation = await stakingContract.pendingUndelegation()

      expect(prevStakeAmount).to.be.equals(STAKED_AMOUNT)
      expect(prevLastRebalanceEpoch).not.to.be.equals(TARGET_EPOCH)
      expect(prevPendingUndelegation).to.be.equals(0)

      await stakingContract.afterUndelegateAll(TARGET_EPOCH)

      const postStakeAmount = await stakingContract.amountStaked()
      const postLastRebalanceEpoch = await stakingContract.epochOfLastRebalance()
      const postPendingUndelegation = await stakingContract.pendingUndelegation()

      expect(postStakeAmount).to.be.equals(0)
      expect(postLastRebalanceEpoch).to.be.equals(TARGET_EPOCH)
      expect(postPendingUndelegation).to.be.equals(STAKED_AMOUNT)
    })
  })

  describe("drainStrategyBalance", async () => {
    it("should transfer funds and reduced deposited amount", async () => {
      const BALANCE = BN(10).pow(18).toString()
      await stakingContract.setTestingConditions(BALANCE, 0, 0, 0, {
        value: BALANCE
      })

      const prevContractBalance = await ethers.provider.getBalance(stakingContract.address)
      const prevUPCBalance = await ethers.provider.getBalance(mockedController.address)

      expect(prevContractBalance).to.be.equal(BALANCE, `contract balance should be ${BALANCE}`)

      await stakingContract.drainStrategyBalance()

      const postBalance = await ethers.provider.getBalance(stakingContract.address)
      const postUPCBalance = await ethers.provider.getBalance(mockedController.address)

      expect(prevUPCBalance.add(BALANCE)).to.be.equal(postUPCBalance)
      expect(postBalance).equals(0, "contract balance should have been drained")
    })
  })
})
