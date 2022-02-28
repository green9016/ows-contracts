import { task } from 'hardhat/config'

task('sendOmnichainToken', 'sends OmnichainTokens to destination chain')
    .addParam('src', 'the address of the local OmnichainToken contract address')
    .addParam('chainid', 'the destination chainId')
    .addParam('dst', 'the destination OmnichainToken contract address')
    .addParam('qty', 'the quantity of tokens to send to the destination chain')

    .setAction(async (taskArgs) => {
        console.log(taskArgs)
        // @ts-expect-error
        const OmnichainToken = await hre.ethers.getContractFactory('OmnichainToken')
        const omnichainToken = await OmnichainToken.attach(taskArgs.src)
        console.log(`omnichainToken.address: ${omnichainToken.address}`)

        // approve
        const approveTx = await omnichainToken.approve(taskArgs.src, taskArgs.qty)
        console.log(`approveTx.hash: ${approveTx.hash}`)

        // @ts-expect-error
        const qty = hre.ethers.BigNumber.from(taskArgs.qty)
        console.log(`qty: ${qty}`)

        // sendTokens
        const tx = await omnichainToken.sendTokens(
            taskArgs.chainid,
            taskArgs.dst,
            qty,
            // @ts-expect-error
            { value: hre.ethers.utils.parseEther('0.0035') }
        )
        console.log(`tx.hash: ${tx.hash}`)
    })
