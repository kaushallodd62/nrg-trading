const { deployments, getNamedAccounts, ethers } = require("hardhat");
const { expect } = require("chai");

describe("EnergyMarket", function () {
    // Deploy the EnergyMarket contract before each test
    let energyMarket, deployer;
    beforeEach(async function () {
        await deployments.fixture();
        deployer = (await getNamedAccounts()).DSO;
        energyMarket = await ethers.getContract("EnergyMarket", deployer);
    });

    // Test the constructor
    describe("constructor", function () {
        it("sets the DSO to the deployer", async function () {
            expect(await energyMarket.getDSO()).to.equal(deployer);
        });
        it("transfers initial supply to the DSO", async function () {
            expect(await energyMarket.balanceOf(deployer)).to.equal(
                await energyMarket.totalSupply()
            );
        });
    });

    // Test the transfer function
    describe("transfer", function () {
        it("reverts if to address is invalid", async function () {
            await expect(
                energyMarket.transfer(ethers.constants.AddressZero, 1)
            ).to.be.revertedWithCustomError(
                energyMarket,
                "EnergyMarket__InvalidAddress"
            );
        });
        it("reverts if value being transferred is greater than balance", async function () {
            expect(
                await energyMarket.transfer(deployer, 1)
            ).to.be.revertedWithCustomError(
                energyMarket,
                "EnergyMarket__InsufficientBalance"
            );
        });
        it("transfers value from sender to receiver", async function () {
            const prosumer1 = (await getNamedAccounts()).prosumer1;
            const prosumer2 = (await getNamedAccounts()).prosumer2;
            await energyMarket.transfer(prosumer1, 1);
            expect(
                await energyMarket.balanceOf(prosumer1)
            ).to.changeTokenBalances(
                energyMarket,
                [deployer, prosumer1],
                [-1, 1]
            );
            await energyMarket.transfer(prosumer2, 1);
            expect(
                await energyMarket.balanceOf(prosumer2)
            ).to.changeTokenBalances(
                energyMarket,
                [deployer, prosumer2],
                [-1, 1]
            );
        });
    });

    // Test the trasferFrom function
    describe("transferFrom", function () {
        it("reverts if to address is invalid", async function () {
            await expect(
                energyMarket.transferFrom(
                    deployer,
                    ethers.constants.AddressZero,
                    1
                )
            ).to.be.revertedWithCustomError(
                energyMarket,
                "EnergyMarket__InvalidAddress"
            );
        });
        it("reverts if value being transferred is greater than balance", async function () {
            await energyMarket.approve(deployer, 1);
            expect(
                await energyMarket.transferFrom(deployer, deployer, 1)
            ).to.be.revertedWithCustomError(
                energyMarket,
                "EnergyMarket__InsufficientBalance"
            );
        });
        it("transfers value from sender to receiver", async function () {
            const prosumer1 = (await getNamedAccounts()).prosumer1;
            const prosumer2 = (await getNamedAccounts()).prosumer2;
            await energyMarket.transfer(prosumer1, 1);
            await energyMarket.transfer(prosumer2, 1);
            await energyMarket
                .connect(await ethers.getSigner(prosumer1))
                .approve(prosumer2, 1);
            await energyMarket
                .connect(await ethers.getSigner(prosumer2))
                .transferFrom(prosumer1, prosumer2, 1);
            expect(
                await energyMarket.balanceOf(prosumer2)
            ).to.changeTokenBalances(
                energyMarket,
                [prosumer1, prosumer2],
                [-1, 1]
            );
        });
    });

    // Test the approve function
    describe("approve", function () {
        it("approves value to spender", async function () {
            const prosumer1 = (await getNamedAccounts()).prosumer1;
            await energyMarket.transfer(prosumer1, 1);
            await energyMarket
                .connect(await ethers.getSigner(prosumer1))
                .approve(deployer, 1);
            expect(await energyMarket.allowance(prosumer1, deployer)).to.equal(
                1
            );
        });
    });

    // Test the increaseAllowance function
    describe("increaseAllowance", function () {
        it("increases allowance by value", async function () {
            const prosumer1 = (await getNamedAccounts()).prosumer1;
            await energyMarket.transfer(prosumer1, 1);
            await energyMarket
                .connect(await ethers.getSigner(prosumer1))
                .approve(deployer, 1);
            await energyMarket
                .connect(await ethers.getSigner(prosumer1))
                .increaseAllowance(deployer, 1);
            expect(await energyMarket.allowance(prosumer1, deployer)).to.equal(
                2
            );
        });
    });

    // Test the decreaseAllowance function
    describe("decreaseAllowance", function () {
        let prosumer1;
        beforeEach(async function () {
            prosumer1 = (await getNamedAccounts()).prosumer1;
            await energyMarket.transfer(prosumer1, 1);
            await energyMarket
                .connect(await ethers.getSigner(prosumer1))
                .approve(deployer, 2);
        });

        it("decreases allowance by value", async function () {
            await energyMarket
                .connect(await ethers.getSigner(prosumer1))
                .decreaseAllowance(deployer, 1);
            expect(await energyMarket.allowance(prosumer1, deployer)).to.equal(
                1
            );
        });

        it("should set allowance to 0 if value is greater than allowance", async function () {
            await energyMarket
                .connect(await ethers.getSigner(prosumer1))
                .decreaseAllowance(deployer, 2);
            expect(await energyMarket.allowance(prosumer1, deployer)).to.equal(
                0
            );
        });
    });

    // Test roundStart function
    describe("roundStart", function () {
        it("reverts if not called by DSO", async function () {
            const prosumer1 = (await getNamedAccounts()).prosumer1;
            await expect(
                energyMarket
                    .connect(await ethers.getSigner(prosumer1))
                    .roundStart()
            ).to.be.revertedWithCustomError(
                energyMarket,
                "EnergyMarket__NotDSO"
            );
        });
        it("should set totalEnergySupplied and totalEnergyDemanded to 0", async function () {
            await energyMarket.roundStart();
            expect(await energyMarket.totalEnergySupplied()).to.equal(0);
            expect(await energyMarket.totalEnergyDemanded()).to.equal(0);
        });
    });

    // Test register function
    describe("register", function () {
        let prosumer1, prosumer2;
        this.beforeEach(async function () {
            prosumer1 = (await getNamedAccounts()).prosumer1;
            prosumer2 = (await getNamedAccounts()).prosumer2;
            await energyMarket
                .connect(await ethers.getSigner(prosumer1))
                .register();
            await energyMarket
                .connect(await ethers.getSigner(prosumer2))
                .register();
        });
        it("should map address of user to index based on totalUsers", async function () {
            expect(await energyMarket.addrIndex(prosumer1)).to.equal(0);
            expect(await energyMarket.addrIndex(prosumer2)).to.equal(1);
        });
        it("should push energy ownership structure to energys array", async function () {
            expect(
                await energyMarket.energys(0, 0).addrOwner.toString()
            ).to.equal(prosumer1);
            expect(await energyMarket.energys(0, 0).energyAmount).to.equal(0);
            expect(await energyMarket.energys(0, 0).energyState).to.equal(0);
            except(await energyMarket.energys(0, 0).timestamp).to.equal(
                ethers.provider.getBlock("latest").timestamp
            );
        });
    });
});
