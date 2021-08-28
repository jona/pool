import { expect } from 'chai'
import { ethers } from 'hardhat'
import '@nomiclabs/hardhat-ethers'

import { Pool__factory, Pool } from '../build/types'

const { getContractFactory, getSigners } = ethers

describe('Pool', () => {
  let pool: Pool

  beforeEach(async () => {
    const signers = await getSigners()

    const poolFactory = (await getContractFactory('Pool', signers[0])) as Pool__factory
    pool = await poolFactory.deploy()
    await pool.deployed()
  })

  describe('deposit', async () => {
    it('should deposit', async () => {
      await pool.deposit(10, { value: 10 })
    })
  })

  describe('withdraw', async () => {
    context('when amount > 0', async () => {
      it('should withdraw', async () => {
        await pool.deposit(100, { value: 100 })
        await pool.depositRewards(100, { value: 100 })
        await pool.withdraw()
      })
    })

    context('when amount not > 0', async () => {
      it('should withdraw', async () => {
        const tx = pool.withdraw()
        await expect(tx).revertedWith('User has nothing to withdraw')
      })
    })
  })

  describe('depositRewards', async () => {
    context('when deposits exist', async () => {
      it('should deposit rewards', async () => {
        await pool.deposit(10, { value: 10 })
        await pool.depositRewards(550, { value: 550 })
      })
    })

    context('when deposits do not exist', async () => {
      it('should fail', async () => {
        const tx = pool.depositRewards(10, { value: 10 })
        await expect(tx).revertedWith('No depositors are available for rewards')
      })
    })
  })
})
