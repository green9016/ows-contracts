import { task } from 'hardhat/config'
import { fujiEndpoint, rinkebyEndpoint } from '../../constants'

task('deployOmnichainToken', 'deploys an OmnichainToken')
    .addParam('name', 'the string name of the token')
    .addParam('symbol', 'the string symbol of the token')
    .setAction(async (taskArgs) => {
        // @ts-expect-error
        const OmnichainToken = await hre.ethers.getContractFactory('OmnichainToken')
        const omnichainToken = await OmnichainToken.deploy(taskArgs.name, taskArgs.symbol, rinkebyEndpoint)
        console.log(`omnichianToken.address: ${omnichainToken.address}`)
    })
