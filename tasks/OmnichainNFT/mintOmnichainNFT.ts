import { task } from 'hardhat/config'

task('mintOmnichainNFT', 'mints a OmnichainNFT')
    .addParam('src', 'the address of the local OmnichainNFT contract')
    .addParam('acc', 'the address of the account that should get the NFT')
    .addParam('uri', 'the uri of the new NFT')
    .setAction(async (taskArgs) => {
        console.log(taskArgs)
        // @ts-expect-error
        const OmnichainNFT = await hre.ethers.getContractFactory('OmnichainNFT')
        const omnichainNFT = await OmnichainNFT.attach(taskArgs.src)
        console.log(`multiChainToken.address: ${omnichainNFT.address}`)

        // mint the token
        const result = await omnichainNFT.safeMint(taskArgs.acc, taskArgs.uri)
        console.log(result)
    })
