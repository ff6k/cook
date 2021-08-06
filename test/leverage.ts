import { ethers, network } from "hardhat";
import { Contract, ContractFactory } from "ethers";
import { expect } from "chai";
import makerAddresses from "./shared/makerAddress.json";
import { getProxy } from "./shared/utilities";
import { DsProxy } from "../typechain/DsProxy";
import { ProxyRegistryInterface } from "../typechain/ProxyRegistryInterface";
import {
  FlashSwapCompoundHandler,
  FlashSwapCompoundHandlerFactory,
  LeveragedBorrowCompound,
  LeveragedBorrowCompoundFactory,
  // CompoundTaker,
  // CompoundTakerFactory,
} from "../typechain";


const BINANCE_ADDRESS = "0x3f5CE5FBFe3E9af3971dD833D26bA9b5C936f0bE";
const WETH_ADDRESS = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const srcAddr = WETH_ADDRESS;
const USDT_ADDRESS = "0xdac17f958d2ee523a2206206994597c13d831ec7";
const destAddr = USDT_ADDRESS;
const C_ETH_ADDRESS = "0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5";
const cCollAddr: string = C_ETH_ADDRESS;
const C_USDT_ADDRESS = "0xf650c3d88d12db855b8bf7d11be6c55a4e07dcc9";
const cBorrAddr: string = C_USDT_ADDRESS;
const overrides = {
  gasLimit: 999999,
  gasPrice: 0,
};

describe("Leverage", function () {
  let proxyAddr: string;
  let web3Proxy: DsProxy;
  let compoundTakerFactory: LeveragedBorrowCompoundFactory;
  let compoundTaker: LeveragedBorrowCompound;
  let flashSwapCompoundHandler: FlashSwapCompoundHandler;
  let flashSwapCompoundHandlerFactory: FlashSwapCompoundHandlerFactory;
  let destTokenContract: Contract;
  let dsGuardFactory: ContractFactory;
  let dsGuardFactoryContract: Contract;
  let account: string;

  beforeEach(async () => {
    const provider = ethers.provider;
    const signer = provider.getSigner();
    const registry: ProxyRegistryInterface = (await ethers.getContractAt(
      "ProxyRegistryInterface",
      makerAddresses["PROXY_REGISTRY"]
    )) as ProxyRegistryInterface;
    const proxyInfo = await getProxy(registry, signer, provider);
    proxyAddr = proxyInfo.proxyAddr;
    flashSwapCompoundHandlerFactory = (await ethers.getContractFactory(
      "FlashSwapCompoundHandler"
    )) as FlashSwapCompoundHandlerFactory;
    compoundTakerFactory = (await ethers.getContractFactory(
      "LeveragedBorrowCompound"
    )) as LeveragedBorrowCompoundFactory;
    flashSwapCompoundHandler = await flashSwapCompoundHandlerFactory.deploy();
    await flashSwapCompoundHandler.deployed();
    compoundTaker = await compoundTakerFactory.deploy();
    await compoundTaker.deployed();
    destTokenContract = await ethers.getContractAt("IERC20", destAddr)
    dsGuardFactory = (await ethers.getContractFactory("DSGuardFactory")) as ContractFactory;
    dsGuardFactoryContract = await dsGuardFactory.deploy();
    await dsGuardFactoryContract.deployed();
    account = await signer.getAddress();
    console.log("User address", account);
    console.log("dest address", destAddr);
    console.log("Proxy address", proxyAddr);
    console.log("FlashSwapCompoundHandler address", flashSwapCompoundHandler.address);
    await network.provider.request({
            method: "hardhat_impersonateAccount",
            // Binance account
            params: [BINANCE_ADDRESS]
    })
    await destTokenContract.connect(provider.getSigner(BINANCE_ADDRESS)).transfer(await signer.getAddress(), '10000000');
    const destTokenBal = await destTokenContract.balanceOf(account);
    console.log("User USDT balance: %s", ethers.utils.formatUnits(destTokenBal, 'wei'));
    web3Proxy = (await ethers.getContractAt("DSProxy", proxyAddr)) as DsProxy;
    signer.sendTransaction({to: proxyAddr, value: ethers.utils.parseEther('5')});
  });

  it("creates", async () => {
    const srcAmount = '0';
    const destAmount = '1000000';
    await destTokenContract.approve(proxyAddr, '1000000');
    const proxyBal = await destTokenContract.balanceOf(proxyAddr)
    console.log("Proxy USDT balance: %s", ethers.utils.formatUnits(proxyBal, 'wei'));
    // console.log(dsGuardFactoryContract.address);
    const callData = compoundTaker.interface.encodeFunctionData(
      "startLeveragedLoan",
      [
        cCollAddr,
        cBorrAddr,
        srcAddr,
        destAddr,
        srcAmount,
        destAmount,
        flashSwapCompoundHandler.address,
        dsGuardFactoryContract.address
      ]
    );
    await web3Proxy.execute(compoundTaker.address, callData);

  });
});
