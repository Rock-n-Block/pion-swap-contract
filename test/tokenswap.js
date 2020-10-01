const BN = require("bn.js");
const chai = require("chai");
const { expect } = require("chai");
const helper = require("./utils/utils.js");
const expectRevert = require("./utils/expectRevert.js");
chai.use(require("chai-bn")(BN));


const  ERC20Mock = artifacts.require('ERC20Mock');
const TokenSwap = artifacts.require('TokenSwap');

const TOKEN_AMOUNT = new BN((10 ** 18).toString());
const ETH_ZERO_ADDERSS = '0x0000000000000000000000000000000000000000'

contract(
    'TokenSwap',
    ([
        deployer,
        manager,
        account1,
        account2
    ]) => {
        let tokenSwap;
        let oldToken;
        let newToken;
        
        beforeEach(async () => {
            // Init contracts

            oldToken = await ERC20Mock.new(
                'Old Token', 
                'OLD', 
                web3.utils.toWei('1000'), 
                {from: deployer}
            )

            newToken = await ERC20Mock.new(
                'New Token', 
                'NEW', 
                web3.utils.toWei('1000'), 
                {from: deployer}
            )

            tokenSwap = await TokenSwap.new(oldToken.address, newToken.address, manager, {from: deployer});
        })

        it("#0 deploy validation", async () => {
            expect(await tokenSwap.oldToken()).to.be.equals(oldToken.address);
            expect(await tokenSwap.newToken()).to.be.equals(newToken.address);
            expect(await tokenSwap.owner()).to.be.equals(manager);
            expect(await tokenSwap.balance()).to.be.zero;
        })

        it("#1 should swap", async () => {
            await oldToken.mint(account1, TOKEN_AMOUNT);
            expect(
                await oldToken.balanceOf(account1)
            ).to.be.bignumber.that.equals(TOKEN_AMOUNT);
            
            await newToken.mint(tokenSwap.address, TOKEN_AMOUNT);
            expect(
                await newToken.balanceOf(tokenSwap.address)
            ).to.be.bignumber.that.equals(TOKEN_AMOUNT);
            
            await oldToken.approve(tokenSwap.address, TOKEN_AMOUNT, {from: account1})
            expect(
                await oldToken.allowance(account1, tokenSwap.address)
            ).to.be.bignumber.that.equals(TOKEN_AMOUNT)

            await tokenSwap.swapTokens(TOKEN_AMOUNT, {from: account1})
            expect(
                await newToken.balanceOf(account1)
            ).to.be.bignumber.that.equals(TOKEN_AMOUNT)
            expect(
                await tokenSwap.getSwappedAmount(account1)
            ).to.be.bignumber.that.equals(TOKEN_AMOUNT)
        })

        it("#1 should swap with multiple addresses", async () => {
            const doubleAmount = TOKEN_AMOUNT.mul(new BN("2"));
            await oldToken.mint(account1, TOKEN_AMOUNT);
            expect(
                await oldToken.balanceOf(account1)
            ).to.be.bignumber.that.equals(TOKEN_AMOUNT);
            
            await oldToken.mint(account2, TOKEN_AMOUNT);
            expect(
                await oldToken.balanceOf(account2)
            ).to.be.bignumber.that.equals(TOKEN_AMOUNT);

            await newToken.mint(tokenSwap.address, doubleAmount);
            expect(
                await newToken.balanceOf(tokenSwap.address)
            ).to.be.bignumber.that.equals(doubleAmount);
            
            await oldToken.approve(tokenSwap.address, TOKEN_AMOUNT, {from: account1})
            expect(
                await oldToken.allowance(account1, tokenSwap.address)
            ).to.be.bignumber.that.equals(TOKEN_AMOUNT)

            await oldToken.approve(tokenSwap.address, TOKEN_AMOUNT, {from: account2})
            expect(
                await oldToken.allowance(account2, tokenSwap.address)
            ).to.be.bignumber.that.equals(TOKEN_AMOUNT)

            await tokenSwap.swapTokens(TOKEN_AMOUNT, {from: account1})
            expect(
                await newToken.balanceOf(account1)
            ).to.be.bignumber.that.equals(TOKEN_AMOUNT)
            expect(
                await tokenSwap.getSwappedAmount(account1)
            ).to.be.bignumber.that.equals(TOKEN_AMOUNT)

            await tokenSwap.swapTokens(TOKEN_AMOUNT, {from: account2})
            expect(
                await newToken.balanceOf(account2)
            ).to.be.bignumber.that.equals(TOKEN_AMOUNT)
            expect(
                await tokenSwap.getSwappedAmount(account2)
            ).to.be.bignumber.that.equals(TOKEN_AMOUNT)
        })

        it("#2 should not swap if new token not supplied", async () => {
            await oldToken.mint(account1, TOKEN_AMOUNT);
            expect(
                await oldToken.balanceOf(account1)
            ).to.be.bignumber.that.equals(TOKEN_AMOUNT);
            
            await oldToken.approve(tokenSwap.address, TOKEN_AMOUNT, {from: account1})
            expect(
                await oldToken.allowance(account1, tokenSwap.address)
            ).to.be.bignumber.that.equals(TOKEN_AMOUNT)

            expect(
                await newToken.balanceOf(tokenSwap.address)
            ).to.be.bignumber.zero;

            await expectRevert(
                tokenSwap.swapTokens(TOKEN_AMOUNT, {from: account1}),
                "ERC20: transfer amount exceeds balance"
            )           
        })

        it("#3 should not swap without approve", async () => {
            await oldToken.mint(account1, TOKEN_AMOUNT);
            expect(
                await oldToken.balanceOf(account1)
            ).to.be.bignumber.that.equals(TOKEN_AMOUNT);
            
            await newToken.mint(tokenSwap.address, TOKEN_AMOUNT);
            expect(
                await newToken.balanceOf(tokenSwap.address)
            ).to.be.bignumber.that.equals(TOKEN_AMOUNT);
            
            expect(
                await oldToken.allowance(account1, tokenSwap.address)
            ).to.be.bignumber.zero;

            await expectRevert(
                tokenSwap.swapTokens(TOKEN_AMOUNT, {from: account1}),
                "ERC20: transfer amount exceeds allowance"
            )
        })

        it("#4 should change old token", async () => {
            const prevOldToken = await tokenSwap.oldToken()
            
            const nextOldTokenContract = await ERC20Mock.new(
                'Next Old Token', 
                'NOLD', 
                web3.utils.toWei('1000'), 
                {from: deployer}
            )

            await expectRevert(
                tokenSwap.setOldToken(nextOldTokenContract.address, {from: account1}),
                "Ownable: caller is not the owner"
            )

            await tokenSwap.setOldToken(nextOldTokenContract.address, {from: manager});

            const nextOldToken = await tokenSwap.oldToken();
            expect(nextOldToken).to.be.equals(nextOldTokenContract.address);
            expect(nextOldToken).to.not.be.equals(prevOldToken);

        })

        it("#5 should change new token", async () => {
            const prevNewToken = await tokenSwap.newToken()
            
            const nextNewTokenContract = await ERC20Mock.new(
                'Next New Token', 
                'NNEW', 
                web3.utils.toWei('1000'), 
                {from: deployer}
            )

            await expectRevert(
                tokenSwap.setNewToken(nextNewTokenContract.address, {from: account1}),
                "Ownable: caller is not the owner"
            )

            await tokenSwap.setNewToken(nextNewTokenContract.address, {from: manager});

            const nextNewToken = await tokenSwap.newToken();
            expect(nextNewToken).to.be.equals(nextNewTokenContract.address);
            expect(nextNewToken).to.not.be.equals(prevNewToken);

        })

        it("#6 should withdraw new token", async () => {
            expect(
                await newToken.balanceOf(tokenSwap.address)
            ).to.be.bignumber.zero;

            await newToken.mint(tokenSwap.address, TOKEN_AMOUNT);
            expect(
                await newToken.balanceOf(tokenSwap.address)
            ).to.be.bignumber.that.equals(TOKEN_AMOUNT);
            
            expect(
                await newToken.balanceOf(account1)
            ).to.be.bignumber.zero;

            await expectRevert(
                tokenSwap.withdrawNewToken(account1, TOKEN_AMOUNT, {from:account1}),
                "Ownable: caller is not the owner"
            )
            await tokenSwap.withdrawNewToken(account1, TOKEN_AMOUNT, {from:manager})

            expect(
                await newToken.balanceOf(tokenSwap.address)
            ).to.be.bignumber.zero;
            
            expect(
                await newToken.balanceOf(account1)
            ).to.be.bignumber.that.equals(TOKEN_AMOUNT);
        })

        it("#7 should withdraw custom token", async () => {
            const customToken = await ERC20Mock.new(
                'Custom Token', 
                'CST', 
                web3.utils.toWei('1000'), 
                {from: deployer}
            )

            expect(
                await customToken.balanceOf(tokenSwap.address)
            ).to.be.bignumber.zero;

            await customToken.mint(tokenSwap.address, TOKEN_AMOUNT);
            expect(
                await customToken.balanceOf(tokenSwap.address)
            ).to.be.bignumber.that.equals(TOKEN_AMOUNT);
            
            expect(
                await customToken.balanceOf(account1)
            ).to.be.bignumber.zero;

            await expectRevert(
                tokenSwap.withdrawCustomToken(customToken.address, account1, TOKEN_AMOUNT, {from:account1}),
                "Ownable: caller is not the owner"
            )
            await expectRevert(
                tokenSwap.withdrawCustomToken(oldToken.address, account1, TOKEN_AMOUNT, {from:manager}),
                "TokenSwap: cannot withdraw old token"
            )

            await tokenSwap.withdrawCustomToken(customToken.address, account1, TOKEN_AMOUNT, {from:manager})

            expect(
                await customToken.balanceOf(tokenSwap.address)
            ).to.be.bignumber.zero;
            
            expect(
                await customToken.balanceOf(account1)
            ).to.be.bignumber.that.equals(TOKEN_AMOUNT);
        })
        
    }
)