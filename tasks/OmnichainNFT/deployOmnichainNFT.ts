import { task } from 'hardhat/config'
import { fujiEndpoint, rinkebyEndpoint, mumbaiEndpoint, bsctEndpoint } from '../../constants'

task('deployOmnichainNFT', 'deploys an OmnichainNFT')
    .addParam('name', 'the string name of the NFT')
    .addParam('symbol', 'the string symbol of the NFT')
    .setAction(async (taskArgs) => {
        // @ts-expect-error
        const OmnichainNFT = await hre.ethers.getContractFactory('OmnichainNFT')
        const omnichainNFT = await OmnichainNFT.deploy(taskArgs.name, taskArgs.symbol, bsctEndpoint)
        console.log(`omnichainNFT.address: ${omnichainNFT.address}`)
    })
