import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";

dotenv.config();

const PRIVATE_KEY = process.env.PRIVATE_KEY || ''
const RINKEBY_API_KEY = process.env.RINKEBY_API_KEY || 'your rinkeby api key'


const config: HardhatUserConfig = {
  solidity: "0.8.4",
  networks: {
    rinkeby: {
      url: RINKEBY_API_KEY,
      accounts:
        PRIVATE_KEY !== '' ? [PRIVATE_KEY] : [],
    },
  }
};

export default config;
