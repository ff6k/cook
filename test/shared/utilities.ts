import {Contract, providers, Signer} from "ethers";
import {ethers} from "hardhat";
import {ProxyRegistryInterface} from "../../typechain/ProxyRegistryInterface";
import {CallOverrides} from "ethers/lib/ethers";
import {DsProxy} from "../../typechain/DsProxy";

const NULL_ADDRESS = "0x0000000000000000000000000000000000000000";

export async function getProxy(
    registry: ProxyRegistryInterface,
    acc: Signer,
    provider: providers.JsonRpcProvider
) {
    const accontAddress : string = await acc.getAddress();
    let proxyAddr = await registry.proxies(accontAddress);

    if (proxyAddr === NULL_ADDRESS) {
        await registry.build(accontAddress, {from: accontAddress} as CallOverrides);
        proxyAddr = await registry.proxies(accontAddress);
    }

    const proxy : DsProxy = await ethers.getContractAt("DSProxy", proxyAddr) as DsProxy;
    let web3proxy = null;

    if (provider != null) {
        web3proxy = await ethers.getContractAt("DSProxy", proxyAddr);
    }

    return { proxy, proxyAddr, web3proxy };
}