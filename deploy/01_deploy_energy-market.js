const { network } = require("hardhat");
const { developerChains } = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments;
    const { DSO } = await getNamedAccounts();
    const args = [];

    log("------------------------------------------------------------------");
    log(
        `Deploying EnergyMarket.sol with DSO address: ${DSO} and waiting for confirmation...`
    );
    // Deploying EnergyMarket.sol contract
    const energyMarket = await deploy("EnergyMarket", {
        from: DSO,
        args: args,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    });
    log("EnergyMarket deployed at:", energyMarket.address);

    // Verifying contracts on Etherscan
    if (
        !developerChains.includes(network.name) &&
        process.env.ETHERSCAN_API_KEY
    ) {
        await verify(energyMarket.address, args);
    }
    log("------------------------------------------------------------------");
};
