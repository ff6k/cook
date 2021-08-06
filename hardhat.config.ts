import { task } from "hardhat/config";
import "@nomiclabs/hardhat-waffle";
import "hardhat-typechain";
import { HardhatUserConfig } from "hardhat/config";

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (args, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(await account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config: HardhatUserConfig = {
  networks: {
    localhost: {
      url: "http://localhost:8545"
    },



    hardhat: {

      accounts: {
        mnemonic: "clutch captain shoe salt awake harvest setup primary inmate ugly among become",
      },

      forking: {
        url: "https://eth-mainnet.alchemyapi.io/v2/H1fS_0d_pksxPz7Ws6SRYM_x1Szh6fp7",
        blockNumber: 11169308
      }

    }

  },
  solidity: "0.6.12",
};

export default config;
