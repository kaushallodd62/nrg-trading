const { deployments, getNamedAccounts, ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");

describe("EnergyMarket", function () {
    // Deploy the EnergyMarket contract before each test
    let energyMarket, deployer;
    this.beforeEach(async function () {
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
            await expect(energyMarket.transfer(ethers.constants.AddressZero, 1))
                .to.be.revertedWithCustomError(
                    energyMarket,
                    "EnergyMarket__InvalidAddress"
                )
                .withArgs(ethers.constants.AddressZero);
        });
        it("reverts if value being transferred is greater than balance", async function () {
            const prosumer1 = (await getNamedAccounts()).prosumer1;
            expect(
                energyMarket
                    .connect(await ethers.getSigner(prosumer1))
                    .transfer(deployer, 1)
            )
                .to.be.revertedWithCustomError(
                    energyMarket,
                    "EnergyMarket__InsufficientBalance"
                )
                .withArgs(0, 1);
        });
        it("transfers value from sender to receiver", async function () {
            const prosumer1 = (await getNamedAccounts()).prosumer1;
            const prosumer2 = (await getNamedAccounts()).prosumer2;
            await energyMarket.transfer(prosumer1, 1);
            expect(await energyMarket.balanceOf(prosumer1)).to.equal(1);
            await energyMarket.transfer(prosumer2, 1);
            expect(await energyMarket.balanceOf(prosumer2)).to.equal(1);
        });
        it("emits a Transfer event", async function () {
            const prosumer1 = (await getNamedAccounts()).prosumer1;
            await expect(energyMarket.transfer(prosumer1, 1))
                .to.emit(energyMarket, "Transfer")
                .withArgs(deployer, prosumer1, 1);
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
            )
                .to.be.revertedWithCustomError(
                    energyMarket,
                    "EnergyMarket__InvalidAddress"
                )
                .withArgs(ethers.constants.AddressZero);
        });
        it("reverts if value being transferred is greater than balance", async function () {
            const prosumer1 = (await getNamedAccounts()).prosumer1;
            expect(
                energyMarket
                    .connect(await ethers.getSigner(prosumer1))
                    .transferFrom(prosumer1, deployer, 1)
            )
                .to.be.revertedWithCustomError(
                    energyMarket,
                    "EnergyMarket__InsufficientBalance"
                )
                .withArgs(0, 1);
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
            expect(await energyMarket.balanceOf(prosumer1)).to.equal(0);
            expect(await energyMarket.balanceOf(prosumer2)).to.equal(2);
        });
        it("emits a Transfer event", async function () {
            const prosumer1 = (await getNamedAccounts()).prosumer1;
            const prosumer2 = (await getNamedAccounts()).prosumer2;
            await energyMarket.transfer(prosumer1, 1);
            await energyMarket
                .connect(await ethers.getSigner(prosumer1))
                .approve(prosumer2, 1);
            await expect(
                energyMarket
                    .connect(await ethers.getSigner(prosumer2))
                    .transferFrom(prosumer1, prosumer2, 1)
            )
                .to.emit(energyMarket, "Transfer")
                .withArgs(prosumer1, prosumer2, 1);
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
        it("emits an Approval event", async function () {
            const prosumer1 = (await getNamedAccounts()).prosumer1;
            await energyMarket.transfer(prosumer1, 1);
            await expect(
                energyMarket
                    .connect(await ethers.getSigner(prosumer1))
                    .approve(deployer, 1)
            )
                .to.emit(energyMarket, "Approval")
                .withArgs(prosumer1, deployer, 1);
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
        it("emits an Approval event", async function () {
            const prosumer1 = (await getNamedAccounts()).prosumer1;
            await energyMarket.transfer(prosumer1, 1);
            await energyMarket
                .connect(await ethers.getSigner(prosumer1))
                .approve(deployer, 1);
            await expect(
                energyMarket
                    .connect(await ethers.getSigner(prosumer1))
                    .increaseAllowance(deployer, 1)
            )
                .to.emit(energyMarket, "Approval")
                .withArgs(prosumer1, deployer, 2);
        });
    });

    // Test the decreaseAllowance function
    describe("decreaseAllowance", function () {
        let prosumer1;
        this.beforeEach(async function () {
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
                .decreaseAllowance(deployer, 3);
            expect(await energyMarket.allowance(prosumer1, deployer)).to.equal(
                0
            );
        });
        it("emits an Approval event", async function () {
            await expect(
                energyMarket
                    .connect(await ethers.getSigner(prosumer1))
                    .decreaseAllowance(deployer, 1)
            )
                .to.emit(energyMarket, "Approval")
                .withArgs(prosumer1, deployer, 1);
            await expect(
                energyMarket
                    .connect(await ethers.getSigner(prosumer1))
                    .decreaseAllowance(deployer, 3)
            )
                .to.emit(energyMarket, "Approval")
                .withArgs(prosumer1, deployer, 0);
        });
    });

    // Test the mint function
    describe("mint", function () {
        let prosumer1;
        this.beforeEach(async function () {
            prosumer1 = (await getNamedAccounts()).prosumer1;
        });
        it("reverts if not called by DSO", async function () {
            const prosumer1 = (await getNamedAccounts()).prosumer1;
            await expect(
                energyMarket
                    .connect(await ethers.getSigner(prosumer1))
                    .mint(deployer, ethers.utils.parseUnits("1", 18))
            )
                .to.be.revertedWithCustomError(
                    energyMarket,
                    "EnergyMarket__NotDSO"
                )
                .withArgs(prosumer1);
        });
        it("should increase totalSupply", async function () {
            expect(
                await energyMarket.mint(
                    deployer,
                    ethers.utils.parseUnits("1", 18)
                )
            );
            const expectedSupply = ethers.utils
                .parseUnits("10000000", 18)
                .add(ethers.utils.parseUnits("1", 18));
            expect(await energyMarket.totalSupply()).to.equal(expectedSupply);
        });
        it("should increase balance of receiver", async function () {
            await energyMarket.mint(
                prosumer1,
                ethers.utils.parseUnits("1", 18)
            );
            expect(await energyMarket.balanceOf(prosumer1)).to.equal(
                ethers.utils.parseUnits("1", 18)
            );
        });
        it("should emit Transfer event", async function () {
            await expect(
                energyMarket.mint(prosumer1, ethers.utils.parseUnits("1", 18))
            )
                .to.emit(energyMarket, "Transfer")
                .withArgs(
                    ethers.constants.AddressZero,
                    prosumer1,
                    ethers.utils.parseUnits("1", 18)
                );
        });
    });

    // Test Burn function
    describe("burn", function () {
        let prosumer1;
        this.beforeEach(async function () {
            prosumer1 = (await getNamedAccounts()).prosumer1;
            await energyMarket.mint(
                prosumer1,
                ethers.utils.parseUnits("1", 18)
            );
        });
        it("reverts if not called by DSO", async function () {
            await expect(
                energyMarket
                    .connect(await ethers.getSigner(prosumer1))
                    .burn(deployer, 1)
            )
                .to.be.revertedWithCustomError(
                    energyMarket,
                    "EnergyMarket__NotDSO"
                )
                .withArgs(prosumer1);
        });
        it("reverts if amount is greater than balance", async function () {
            await expect(
                energyMarket.burn(prosumer1, ethers.utils.parseUnits("2", 18))
            )
                .to.be.revertedWithCustomError(
                    energyMarket,
                    "EnergyMarket__InsufficientBalance"
                )
                .withArgs(
                    ethers.utils.parseUnits("1", 18),
                    ethers.utils.parseUnits("2", 18)
                );
        });
        it("should decrease totalSupply", async function () {
            await energyMarket.burn(
                prosumer1,
                ethers.utils.parseUnits("1", 18)
            );
            const expectedSupply = ethers.utils.parseUnits("10000000", 18);
            expect(await energyMarket.totalSupply()).to.equal(expectedSupply);
        });
        it("should decrease balance of receiver", async function () {
            await energyMarket.burn(
                prosumer1,
                ethers.utils.parseUnits("1", 18)
            );
            expect(await energyMarket.balanceOf(prosumer1)).to.equal(0);
        });
        it("should emit Transfer event", async function () {
            await expect(
                energyMarket.burn(prosumer1, ethers.utils.parseUnits("1", 18))
            )
                .to.emit(energyMarket, "Transfer")
                .withArgs(
                    prosumer1,
                    ethers.constants.AddressZero,
                    ethers.utils.parseUnits("1", 18)
                );
        });
    });

    // Test Getter functions
    describe("getters", function () {
        it("should return the address of DSO", async function () {
            expect(await energyMarket.getDSO()).to.equal(deployer);
        });
        it("should return totalEnergySupplied", async function () {
            expect(await energyMarket.getTotalEnergySupplied()).to.equal(0);
        });
        it("should return totalEnergyDemanded", async function () {
            expect(await energyMarket.getTotalEnergyDemanded()).to.equal(0);
        });
        it("should return totalUsers", async function () {
            expect(await energyMarket.getTotalUsers()).to.equal(0);
        });
        it("should return endTime of round", async function () {
            expect(await energyMarket.getEndTime()).to.equal(0);
        });
        it("should return the supplyIndex", async function () {
            expect(await energyMarket.getSupplyIndex()).to.equal(0);
        });
        it("should return the demandIndex", async function () {
            expect(await energyMarket.getDemandIndex()).to.equal(0);
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
            )
                .to.be.revertedWithCustomError(
                    energyMarket,
                    "EnergyMarket__NotDSO"
                )
                .withArgs(prosumer1);
        });
        it("should set totalEnergySupplied and totalEnergyDemanded to 0", async function () {
            await energyMarket.roundStart();
            expect(await energyMarket.getTotalEnergySupplied()).to.equal(0);
            expect(await energyMarket.getTotalEnergyDemanded()).to.equal(0);
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
            expect(await energyMarket.getIndexFromAddress(prosumer1)).to.equal(
                0
            );
            expect(await energyMarket.getIndexFromAddress(prosumer2)).to.equal(
                1
            );
        });
        it("should push energy ownership structure to energys array", async function () {
            const { addrOwner, energyAmount, energyState /*, timestamp */ } =
                await energyMarket.getEnergyOwnershipInfo(prosumer1, 0);
            expect(addrOwner).to.equal(prosumer1);
            expect(energyAmount.toNumber()).to.equal(0);
            expect(energyState.toNumber()).to.equal(0);
            // expect(timestamp.toNumber()).to.equal((await time.latest()) - 1);
        });
    });

    // Test inject function
    describe("inject", function () {
        let prosumer1;
        this.beforeEach(async function () {
            prosumer1 = (await getNamedAccounts()).prosumer1;
            await energyMarket
                .connect(await ethers.getSigner(prosumer1))
                .register();
        });
        it("reverts if not called by DSO", async function () {
            await expect(
                energyMarket
                    .connect(await ethers.getSigner(prosumer1))
                    .inject(prosumer1, 1)
            )
                .to.be.revertedWithCustomError(
                    energyMarket,
                    "EnergyMarket__NotDSO"
                )
                .withArgs(prosumer1);
        });
        it("should create EnergyOwnership structure and push to energys array", async function () {
            await energyMarket.inject(prosumer1, 1);
            const { addrOwner, energyAmount, energyState /*, timestamp */ } =
                await energyMarket.getEnergyOwnershipInfo(prosumer1, 1);
            expect(addrOwner).to.equal(prosumer1);
            expect(energyAmount.toNumber()).to.equal(1);
            expect(energyState.toNumber()).to.equal(1);
            // expect(timestamp.toNumber()).to.equal((await time.latest()) - 1);
        });
        it("should perform aggregate calculations", async function () {
            await energyMarket.inject(prosumer1, 1);
            await energyMarket.inject(prosumer1, 2);
            const { addrOwner, energyAmount, energyState /*, timestamp */ } =
                await energyMarket.getEnergyOwnershipInfo(prosumer1, 1);
            expect(addrOwner).to.equal(prosumer1);
            expect(energyAmount.toNumber()).to.equal(3);
            expect(energyState.toNumber()).to.equal(1);
            // expect(timestamp.toNumber()).to.equal(await time.latest());
        });
    });

    // Test requestSell function
    describe("requestSell", function () {
        let prosumer1;
        this.beforeEach(async function () {
            prosumer1 = (await getNamedAccounts()).prosumer1;
            await energyMarket
                .connect(await ethers.getSigner(prosumer1))
                .register();
            await energyMarket.inject(prosumer1, 100);
        });
        it("reverts if amount requested is more than amount injected", async function () {
            await energyMarket.roundStart();
            await expect(
                energyMarket
                    .connect(await ethers.getSigner(prosumer1))
                    .requestSell(101)
            )
                .to.be.revertedWithCustomError(
                    energyMarket,
                    "EnergyMarket__InsufficientEnergyInjected"
                )
                .withArgs(100, 101);
        });
        it("reverts if request made before round start", async function () {
            await expect(
                energyMarket
                    .connect(await ethers.getSigner(prosumer1))
                    .requestSell(80)
            ).to.be.revertedWithCustomError(
                energyMarket,
                "EnergyMarket__OutsideRound"
            );
            /*.withArgs(
                    await time.latest(),
                    await energyMarket.getStartTime(),
                    await energyMarket.getEndTime()
                );*/
        });
        it("reverts if request made after round ends", async function () {
            await energyMarket.roundStart();
            await time.increase(3601);
            await expect(
                energyMarket
                    .connect(await ethers.getSigner(prosumer1))
                    .requestSell(80)
            ).to.be.revertedWithCustomError(
                energyMarket,
                "EnergyMarket__OutsideRound"
            );
            /*.withArgs(
                    await time.latest(),
                    await energyMarket.getStartTime(),
                    await energyMarket.getEndTime()
                );*/
        });
        it("should create EnergyOwnership structure and push to energys array", async function () {
            await energyMarket.roundStart();
            await energyMarket
                .connect(await ethers.getSigner(prosumer1))
                .requestSell(80);
            const { addrOwner, energyAmount, energyState /*, timestamp */ } =
                await energyMarket.getEnergyOwnershipInfo(prosumer1, 2);
            expect(addrOwner).to.equal(prosumer1);
            expect(energyAmount.toNumber()).to.equal(80);
            expect(energyState.toNumber()).to.equal(2);
            // expect(timestamp.toNumber()).to.equal((await time.latest()) - 1);
        });
        it("should update the amount of injected energy", async function () {
            await energyMarket.roundStart();
            await energyMarket
                .connect(await ethers.getSigner(prosumer1))
                .requestSell(80);
            const { addrOwner, energyAmount, energyState /*, timestamp */ } =
                await energyMarket.getEnergyOwnershipInfo(prosumer1, 1);
            expect(addrOwner).to.equal(prosumer1);
            expect(energyAmount.toNumber()).to.equal(20);
            expect(energyState.toNumber()).to.equal(1);
            // expect(timestamp.toNumber()).to.equal((await time.latest()) - 1);
        });
        it("should create Supply structure and push to supplies array", async function () {
            await energyMarket.roundStart();
            await energyMarket
                .connect(await ethers.getSigner(prosumer1))
                .requestSell(80);
            const { addrProsumer, energySupplied } =
                await energyMarket.getSupplyInfo(0);
            expect(addrProsumer).to.equal(prosumer1);
            expect(energySupplied.toNumber()).to.equal(80);
        });
        it("should increment supply index", async function () {
            await energyMarket.roundStart();
            await energyMarket
                .connect(await ethers.getSigner(prosumer1))
                .requestSell(80);
            expect(await energyMarket.getSupplyIndex()).to.equal(1);
        });
        it("should update totalEnergySupply", async function () {
            await energyMarket.roundStart();
            await energyMarket
                .connect(await ethers.getSigner(prosumer1))
                .requestSell(80);
            expect(await energyMarket.getTotalEnergySupplied()).to.equal(80);
        });
    });

    // Test requestBuy function
    describe("requestBuy", function () {
        let consumer1;
        this.beforeEach(async function () {
            consumer1 = (await getNamedAccounts()).consumer1;
            await energyMarket
                .connect(await ethers.getSigner(consumer1))
                .register();
        });
        it("reverts if amount requested is 0", async function () {
            await energyMarket.roundStart();
            await expect(
                energyMarket
                    .connect(await ethers.getSigner(consumer1))
                    .requestBuy(0)
            ).to.be.revertedWithCustomError(
                energyMarket,
                "EnergyMarket__ZeroEnergyAmount"
            );
        });
        it("reverts if balance is insufficient", async function () {
            await energyMarket.roundStart();
            await expect(
                energyMarket
                    .connect(await ethers.getSigner(consumer1))
                    .requestBuy(1)
            )
                .to.be.revertedWithCustomError(
                    energyMarket,
                    "EnergyMarket__InsufficientBalance"
                )
                .withArgs(0, await energyMarket.MAX_ENERGYPRICE());
        });
        it("reverts if request made before round start", async function () {
            await expect(
                energyMarket
                    .connect(await ethers.getSigner(consumer1))
                    .requestBuy(1)
            ).to.be.revertedWithCustomError(
                energyMarket,
                "EnergyMarket__OutsideRound"
            );
            /*.withArgs(
                    await time.latest(),
                    await energyMarket.getStartTime(),
                    await energyMarket.getEndTime()
                );*/
        });
        it("reverts if request made after round ends", async function () {
            await energyMarket.roundStart();
            await time.increase(3601);
            await expect(
                energyMarket
                    .connect(await ethers.getSigner(consumer1))
                    .requestBuy(1)
            ).to.be.revertedWithCustomError(
                energyMarket,
                "EnergyMarket__OutsideRound"
            );
            /*.withArgs(
                    await time.latest(),
                    await energyMarket.getStartTime(),
                    await energyMarket.getEndTime()
                );*/
        });
        it("should create EnergyOwnership structure and push to energys array", async function () {
            await energyMarket.transfer(
                consumer1,
                ethers.utils.parseEther("1")
            );
            await energyMarket.roundStart();
            await energyMarket
                .connect(await ethers.getSigner(consumer1))
                .requestBuy(80);
            const { addrOwner, energyAmount, energyState /*, timestamp */ } =
                await energyMarket.getEnergyOwnershipInfo(consumer1, 1);
            expect(addrOwner).to.equal(consumer1);
            expect(energyAmount.toNumber()).to.equal(80);
            expect(energyState.toNumber()).to.equal(2);
            // expect(timestamp.toNumber()).to.equal((await time.latest()) - 1);
        });
        it("should create Demand structure and push to demands array", async function () {
            await energyMarket.transfer(
                consumer1,
                ethers.utils.parseEther("1")
            );
            await energyMarket.roundStart();
            await energyMarket
                .connect(await ethers.getSigner(consumer1))
                .requestBuy(80);
            const { addrConsumer, energyDemanded } =
                await energyMarket.getDemandInfo(0);
            expect(addrConsumer).to.equal(consumer1);
            expect(energyDemanded.toNumber()).to.equal(80);
        });
        it("should increment demand index", async function () {
            await energyMarket.transfer(
                consumer1,
                ethers.utils.parseEther("1")
            );
            await energyMarket.roundStart();
            await energyMarket
                .connect(await ethers.getSigner(consumer1))
                .requestBuy(80);
            expect(await energyMarket.getDemandIndex()).to.equal(1);
        });
        it("should update totalEnergyDemand", async function () {
            await energyMarket.transfer(
                consumer1,
                ethers.utils.parseEther("1")
            );
            await energyMarket.roundStart();
            await energyMarket
                .connect(await ethers.getSigner(consumer1))
                .requestBuy(80);
            expect(await energyMarket.getTotalEnergyDemanded()).to.equal(80);
        });
        it("should update DSO allowance", async function () {
            await energyMarket.transfer(
                consumer1,
                ethers.utils.parseEther("1")
            );
            await energyMarket.roundStart();
            await energyMarket
                .connect(await ethers.getSigner(consumer1))
                .requestBuy(80);
            expect(await energyMarket.allowance(consumer1, deployer)).to.equal(
                80 * (await energyMarket.MAX_ENERGYPRICE()).toNumber()
            );
        });
    });

    // Test Match function
    describe("matching", function () {
        let prosumer1, consumer1;
        this.beforeEach(async function () {
            prosumer1 = (await getNamedAccounts()).prosumer1;
            consumer1 = (await getNamedAccounts()).consumer1;
            await energyMarket
                .connect(await ethers.getSigner(prosumer1))
                .register();
            await energyMarket
                .connect(await ethers.getSigner(consumer1))
                .register();
            await energyMarket.transfer(
                prosumer1,
                ethers.utils.parseEther("1")
            );
            await energyMarket.transfer(
                consumer1,
                ethers.utils.parseEther("1")
            );
            await energyMarket.roundStart();
            await energyMarket.inject(prosumer1, 80);
            await energyMarket
                .connect(await ethers.getSigner(prosumer1))
                .requestSell(80);
            await energyMarket
                .connect(await ethers.getSigner(consumer1))
                .requestBuy(100);
        });
        it("reverts if not called by DSO", async function () {
            await expect(
                energyMarket
                    .connect(await ethers.getSigner(prosumer1))
                    .matching()
            ).to.be.revertedWithCustomError(
                energyMarket,
                "EnergyMarket__NotDSO"
            );
        });
    });
});
