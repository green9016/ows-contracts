import { task } from 'hardhat/config'

task('sendOmnichainNFT', 'sends a OmnichainNFT to destination chain')
    .addParam('src', 'the address of the local OmnichainNFT contract address')
    .addParam('chainid', 'the destination chainId')
    .addParam('dst', 'the destination OmnichainNFT contract address')
    .addParam('id', 'id of the NFT to send')

    .setAction(async (taskArgs) => {
        console.log(taskArgs)
        const id = Number(taskArgs.id)
        // @ts-expect-error
        const OmnichainNFT = await hre.ethers.getContractFactory('OmnichainNFT')
        const omnichainNFT = await OmnichainNFT.attach(taskArgs.src)
        console.log(`omnichainNFT.address: ${omnichainNFT.address}`)

        // approve
        // let approveTx = await multiChainNFT.approve(taskArgs.src, id);
        // console.log(`approveTx.hash: ${approveTx.hash}`);

        console.log(`id: ${id}`)
        // sendTokens
        const tx = await omnichainNFT.sendNFT(
            taskArgs.chainid,
            taskArgs.dst,
            id,
            // @ts-expect-error
            { value: hre.ethers.utils.parseEther('0.1') }
        )
        console.log(`tx.hash: ${tx.hash}`)
    })
