require('dotenv').config({ path: '../.env' })

const TokenSwap = artifacts.require('./TokenSwap.sol');

module.exports = async function (deployer, network, accounts) {
	return deployer.then(async () => {

		const { 
            MANAGER_ADDRESS,
            OLD_TOKEN_ADDRESS,
            NEW_TOKEN_ADDRESS
        } = process.env

        if (MANAGER_ADDRESS == null) {
            throw "Manager address is not defined"
        }

        if (OLD_TOKEN_ADDRESS == null) {
            throw "Old token address address is not defined"
        }

        if (NEW_TOKEN_ADDRESS == null) {
            throw "New token address address is not defined"
        }
        
        console.log('Manager address:    ', MANAGER_ADDRESS);
        console.log('Old token address:   ', OLD_TOKEN_ADDRESS);
        console.log('New token address: ', NEW_TOKEN_ADDRESS);

		// DEPLOY SWAP
        const tokenSwap = await deployer.deploy(
            TokenSwap, 
            OLD_TOKEN_ADDRESS,
            NEW_TOKEN_ADDRESS,
            MANAGER_ADDRESS
        );

        console.log("");
        console.log('Token swap address: ', tokenSwap.address);
	})
}