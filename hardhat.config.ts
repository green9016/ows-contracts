import * as dotenv from 'dotenv'

import { HardhatUserConfig } from 'hardhat/config'
import '@nomiclabs/hardhat-etherscan'
import '@nomiclabs/hardhat-waffle'
import 'hardhat-contract-sizer'
import '@typechain/hardhat'
import 'hardhat-gas-reporter'
import 'solidity-coverage'
import './tasks/deployOmniWars'
import './tasks/mintOmniWars'
import './tasks/OmnichainToken/deployOmnichainToken'
import './tasks/OmnichainToken/sendOmnichainToken'
import './tasks/OmnichainNFT/deployOmnichainNFT'
import './tasks/OmnichainNFT/mintOmnichainNFT'
import './tasks/OmnichainNFT/sendOmnichainNFT'
import './tasks/OmnichainNFT/tokenURIOmnichainNFT'

dotenv.config()

const PRIVATE_KEY = process.env.PRIVATE_KEY || ''
const RINKEBY_API_KEY = process.env.RINKEBY_API_KEY || 'your rinkeby api key'
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || ''
const FUJI_API_KEY = 'https://api.avax-test.network/ext/bc/C/rpc'
const MUMBAI_API_KEY = process.env.MUMBAI_API_KEY || 'your mumbai api key'
const BINANCE_TESTNET_API_KEY = 'https://data-seed-prebsc-1-s1.binance.org:8545'

const config: HardhatUserConfig = {
    solidity: {
        version: '0.8.4',
        settings: {
            optimizer: {
                enabled: true,
                runs: 200
            }
        }
    },

    networks: {
        rinkeby: {
            url: RINKEBY_API_KEY,
            accounts: PRIVATE_KEY !== '' ? [PRIVATE_KEY] : []
        },
        fuji: {
            url: FUJI_API_KEY,
            accounts: PRIVATE_KEY !== '' ? [PRIVATE_KEY] : [],
            gas: 2100000,
            gasPrice: 25000000001
        },
        mumbai: {
            url: MUMBAI_API_KEY,
            accounts: PRIVATE_KEY !== '' ? [PRIVATE_KEY] : [],
            gas: 2100000,
            gasPrice: 25000000001
        },
        bsct: {
            url: BINANCE_TESTNET_API_KEY,
            accounts: PRIVATE_KEY !== '' ? [PRIVATE_KEY] : [],
            gas: 2100000,
            gasPrice: 25000000001
        }
    },
    etherscan: {
        apiKey: ETHERSCAN_API_KEY
    }
}

export default config
