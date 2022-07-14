import { BigNumber } from "ethers"
import { ethers } from "hardhat"

export const getUniswapRouter = (routerAddress: string) =>
  ethers.getContractAt("IUniswapV2Router02", routerAddress)

export const getAmountOut = (
  amountIn: BigNumber,
  reserveIn: BigNumber,
  reserveOut: BigNumber
): BigNumber => {
  const amountInWithFee = amountIn.mul(997)
  const numerator = amountInWithFee.mul(reserveOut)
  const denominator = reserveIn.mul(1000).add(amountInWithFee)
  return numerator.div(denominator)
}
