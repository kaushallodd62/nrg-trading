const { getDSO } = require("./accounts");

async function main() {
    // Getting DSO address
    const DSO = await getDSO();
    console.log("Deploying contract with DSO address:", DSO.address);
    console.log("Account balance:", (await DSO.getBalance()).toString());

    // Deploying NRGToken.sol contract
    const nrgTokenFactory = await hre.ethers.getContractFactory("NRGToken");
    console.log("Deploying NRGToken contract...");
    const nrgTokenContract = await nrgTokenFactory.deploy();
    await nrgTokenContract.deployed();
    console.log("NRGToken deployed to:", nrgTokenContract.address);

    // Deploying EnergyMarket.sol contract
    const energyMarketFactory = await hre.ethers.getContractFactory(
        "EnergyMarket"
    );
    console.log("Deploying EnergyMarket contract...");
    const energyMarketContract = await energyMarketFactory.deploy(
        nrgTokenContract.address
    );
    await energyMarketContract.deployed();
    console.log("EnergyMarket deployed to:", energyMarketContract.address);

    // Verifying contracts on Etherscan
    if (hre.network.name === "goerli") {
        console.log("Verifying contracts on Etherscan...");
        await hre.run("verify:verify", {
            address: nrgTokenContract.address,
            constructorArguments: [],
        });
        await hre.run("verify:verify", {
            address: energyMarketContract.address,
            constructorArguments: [nrgTokenContract.address],
        });
    }
}

main()
    .then(() => process.exit(0))
    .catch((err) => {
        console.error(err);
        process.exit(1);
    });
