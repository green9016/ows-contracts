import { task } from 'hardhat/config'

task('tokenURIOmnichainNFT', 'check a URI of OmnichainNFT')
    .addParam('src', 'the address of the local OmnichainNFT contract')
    .addParam('id', 'the id of the token that should be checked')
    .setAction(async (taskArgs) => {
        console.log(taskArgs)
        // @ts-expect-error
        const OmnichainNFT = await hre.ethers.getContractFactory('OmnichainNFT')
        const omnichainNFT = await OmnichainNFT.attach(taskArgs.src)
        console.log(`omnichainNFT.address: ${omnichainNFT.address}`)

        // mint the token
        const result = await omnichainNFT.tokenURI(Number(taskArgs.id))
        console.log(result)
    })
