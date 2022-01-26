import { ethers } from 'hardhat'
import chai from 'chai'
import { solidity } from 'ethereum-waffle'
import { OmnichainWarsv0 } from '../typechain'
import { BigNumber } from '@ethersproject/bignumber'
const hre = require('hardhat')
chai.use(solidity)
const { expect } = chai

export const ether = (amount: number | string): BigNumber => {
    const weiString = ethers.utils.parseEther(amount.toString())
    return BigNumber.from(weiString)
}

export const unlockAccount = async (address: string) => {
    await hre.network.provider.send('hardhat_impersonateAccount', [address])
    return address
}

describe('OmnichainWarsv0', () => {
    let omnichainWarsv0: OmnichainWarsv0
    let signers: any

    beforeEach(async () => {
        signers = await ethers.getSigners()

        const omnichainWarFactory = await ethers.getContractFactory(
            'OmnichainWarsv0',
            signers[0]
        )
        omnichainWarsv0 = (await omnichainWarFactory.deploy(
            ['Spearmen', 'Swordsmen', 'Hussars', 'Holy Knights', 'Rams', 'Barons', 'Hero'],
            ['https://i.imgur.com/1BYgjyz.jpg', 'https://i.imgur.com/1BYgjyz.jpg', 'https://i.imgur.com/1BYgjyz.jpg', 'https://i.imgur.com/1BYgjyz.jpg', 'https://i.imgur.com/1BYgjyz.jpg', 'https://i.imgur.com/1BYgjyz.jpg', 'https://i.imgur.com/1BYgjyz.jpg'],
            [15, 50, 80, 150, 0, 70],
            [25, 20, 55, 80, 75, 55],
            [40, 15, 35, 100, 75, 45],
            [10, 15, 35, 30, 15, 15],
            [20, 40, 60, 50, 0, 80],
            100,
            0,
            0,
            0
        )) as OmnichainWarsv0
        await omnichainWarsv0.deployed()
    })

    describe('External Free Minting Process', () => {
        it('Minting', async () => {
            await omnichainWarsv0.connect(signers[0]).mint()
            expect(await omnichainWarsv0.balanceOf(signers[0].address, 1)).to.eq(10)
            expect(await omnichainWarsv0.balanceOf(signers[0].address, 2)).to.eq(4)
            expect(await omnichainWarsv0.balanceOf(signers[0].address, 3)).to.eq(1)

            const tokenList = await omnichainWarsv0.getAllTokens(signers[0].address)
            console.log(tokenList)
        })

        it('Combat', async () => {
            await omnichainWarsv0.connect(signers[0]).mint()
            await omnichainWarsv0.connect(signers[0]).combat(1, 2)
        })
    })
})
