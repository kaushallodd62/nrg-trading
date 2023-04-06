require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy");
require("dotenv").config();

const HARDHAT_LOCAL_RPC_URL = "http://127.0.0.1:8545/";
const GOERLI_RPC_URL = process.env.GOERLI_RPC_URL;
const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;
const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            live: false,
            saveDeployments: true,
            tags: ["test", "local"],
        },
        localhost: {
            url: HARDHAT_LOCAL_RPC_URL,
            live: false,
            saveDeployments: true,
            tags: ["local"],
        },
        goerli: {
            url: GOERLI_RPC_URL,
            accounts: [PRIVATE_KEY],
            chainId: 5,
            blockConfirmations: 6,
            live: true,
            saveDeployments: true,
            tags: ["staging"],
        },
        sepolia: {
            url: SEPOLIA_RPC_URL,
            accounts: [PRIVATE_KEY],
            chainID: 11155111,
            blockConfirmations: 6,
            live: true,
            saveDeployments: true,
            tags: ["staging"],
        },
    },
    solidity: "0.8.18",
    paths: {
        root: "./",
        sources: "./contracts",
        tests: "./test",
        deploy: "./deploy",
        cache: "./cache",
        artifacts: "./artifacts",
    },
    gasReporter: {
        enabled: true,
        outputFile: "gas-report.txt",
        noColors: true,
        currency: "USD",
        coinmarketcap: COINMARKETCAP_API_KEY,
    },
    etherscan: {
        apiKey: ETHERSCAN_API_KEY,
    },
    namedAccounts: {
        DSO: {
            default: 0,
        },
        prosumer1: {
            default: 1,
        },
        prosumer2: {
            default: 2,
        },
        prosumer3: {
            default: 3,
        },
        prosumer4: {
            default: 4,
        },
        prosumer5: {
            default: 5,
        },
        consumer1: {
            default: 6,
        },
        consumer2: {
            default: 7,
        },
        consumer3: {
            default: 8,
        },
        consumer4: {
            default: 9,
        },
        consumer5: {
            default: 10,
        },
    },
};
