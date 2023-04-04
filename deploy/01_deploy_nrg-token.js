const { network } = require("hardhat");
const { developerChains } = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments;
    const { DSO } = await getNamedAccounts();
    const args = [];

    log("------------------------------------------------------------------");
    log(
        `Deploying NRGToken.sol with DSO address: ${DSO} and waiting for confirmation...`
    );
    // Deploying NRGToken.sol contract
    const nrgToken = await deploy("NRGToken", {
        from: DSO,
        args: args,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    });
    log("NRGToken deployed at:", nrgToken.address);

    // Verifying contracts on Etherscan
    if (
        !developerChains.includes(network.name) &&
        process.env.ETHERSCAN_API_KEY
    ) {
        await verify(nrgToken.address, args);
    }
    log("------------------------------------------------------------------");
};
