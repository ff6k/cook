import {ethers, network} from "hardhat";
import {expect} from "chai";
import {DsProxy} from "../typechain/DsProxy";
import {ProxyRegistryInterface} from "../typechain/ProxyRegistryInterface";
import makerAddresses from "./shared/makerAddress.json";
import {getProxy} from "./shared/utilities";
import {DsAuth, FlashSwapCompoundHandler, FlashSwapCompoundHandlerFactory} from "../typechain";
import IERC20Artifact from "@openzeppelin/contracts/build/contracts/IERC20.json";
import {Ierc20} from "../typechain/Ierc20";
import {IUniswapV2Pair} from "../typechain/IUniswapV2Pair";
import UniswapV2PairArtifact from "@uniswap/v2-core/build/UniswapV2Pair.json";
import {ParamType} from "ethers/lib/utils";
import {DsGuard} from "../typechain/DsGuard";

describe("FlashSwapCompoundHandler", function () {
    const BINANCE_ADDRESS = "0x3f5CE5FBFe3E9af3971dD833D26bA9b5C936f0bE";
    const DS_GUARD_FACTORY_ADDRESS = "0x5a15566417e6C1c9546523066500bDDBc53F88C7";
    let dsProxy: DsProxy;
    let wbtc: Ierc20;
    let dai: Ierc20;
    let wbtc_eth_pair: IUniswapV2Pair;
    let flashSwapCompoundHandler: FlashSwapCompoundHandler;
    let flashSwapCompoundHandlerFactory: FlashSwapCompoundHandlerFactory;
    let signer: any;
    let dsGuard: DsGuard;

    beforeEach(async () => {
        const provider = ethers.provider;
        signer = provider.getSigner();
        console.log("signer address: %s", await signer.getAddress());
        // Get dsProxy for signer
        const registry: ProxyRegistryInterface = await ethers.getContractAt(
            "ProxyRegistryInterface",
            makerAddresses["PROXY_REGISTRY"]
        ) as ProxyRegistryInterface;
        const proxyInfo = await getProxy(registry, signer, provider);
        dsProxy = proxyInfo.proxy;
        console.log("dsProxy %s", dsProxy.address);
        // Get dsGuard for signer
        await ethers.getContractAt
        console.log("dsAuthority %s", await dsProxy.authority())
        // dsGuard = await ethers.getContractAt
        // Transfer 1 WBTC to dsProxy
        await network.provider.request({
                method: "hardhat_impersonateAccount",
                // Binance account
                params: [BINANCE_ADDRESS]
            }
        )
        wbtc = await ethers.getContractAt(IERC20Artifact.abi, "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599") as Ierc20;
        dai = await ethers.getContractAt(IERC20Artifact.abi, "0x6b175474e89094c44da98b954eedeac495271d0f") as Ierc20;
        await wbtc.connect(provider.getSigner(BINANCE_ADDRESS)).transfer(await signer.getAddress(), 1);
        expect(await wbtc.balanceOf(await signer.getAddress())).to.equal(1);
        // Deploy FlashSwapCompoundHandler
        flashSwapCompoundHandlerFactory = await ethers.getContractFactory("FlashSwapCompoundHandler") as FlashSwapCompoundHandlerFactory;
        flashSwapCompoundHandler = await flashSwapCompoundHandlerFactory.deploy();
        await flashSwapCompoundHandler.deployed();
        console.log("flashSwapCompoundHandler address: %s", flashSwapCompoundHandler.address);
        // Load WBTC/ETH pair
        wbtc_eth_pair = await ethers.getContractAt(UniswapV2PairArtifact.abi, "0xbb2b8038a1640196fbe3e38816f3e67cba72d940") as IUniswapV2Pair;
    });

    it("flash swap", async () => {
        // grant dsProxy access to flashSwapCompoundHandler
        dsProxy.authority()
        await ethers.getContractAt
        // new DsAuth(await signer.getAddress()).authority();
        // flash swap
        const paramsData : string = flashSwapCompoundHandler.interface._encodeParams([ParamType.fromString("address"), ParamType.fromString("address"), ParamType.fromString("address")], [wbtc.address, dai.address, dsProxy.address]);
        await wbtc_eth_pair.swap(2, 0, flashSwapCompoundHandler.address, paramsData);
    });
});