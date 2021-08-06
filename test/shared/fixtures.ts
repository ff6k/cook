import { ethers, waffle } from "hardhat"
import { Signer, Contract } from "ethers"
import dsproxyjson from "../../artifacts/contracts/DSProxy/DSProxy.sol/DSProxy.json"

interface V2Fixture {
  dsproxy: Contract
  // compound: Contract
  // uniswap: Contract
}

export async function v2Fixture(signer: Signer): Promise<V2Fixture> {
  // deploy tokens
  // const dsproxyFactory = await ethers.getContractFactory('DSProxy')
  // const dsproxy = await dsproxyFactory.deploy()
  const dsproxy = await waffle.deployContract(signer, dsproxyjson)

  // const compound = await waffle.deployContract(wallet, ERC20, [expandTo18Decimals(10000)])
  // const uniswap = await waffle.deployContract(wallet, WETH9)

  // initialize V2
  // await factoryV2.createPair(tokenA.address, tokenB.address)
  // const pairAddress = await factoryV2.getPair(tokenA.address, tokenB.address)
  // const pair = new Contract(pairAddress, JSON.stringify(IUniswapV2Pair.abi), provider).connect(wallet)

  // const token0Address = await pair.token0()
  // const token0 = tokenA.address === token0Address ? tokenA : tokenB
  // const token1 = tokenA.address === token0Address ? tokenB : tokenA

  // await factoryV2.createPair(WETH.address, WETHPartner.address)
  // const WETHPairAddress = await factoryV2.getPair(WETH.address, WETHPartner.address)
  // const WETHPair = new Contract(WETHPairAddress, JSON.stringify(IUniswapV2Pair.abi), provider).connect(wallet)

  return {
    dsproxy,
    // compound,
    // uniswap,
  }
}
