// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./NRGToken.sol";

contract EnergyMarket {
    // State Variables
    NRGToken internal immutable tokenContract;
    uint256 internal totalEnergySupplied;
    uint256 internal totalEnergyDemanded;
    uint256 internal totalUsers;
    address internal immutable DSO;
    uint256 internal constant MAX_ENERGYPRICE = 555;
    uint256 internal etime;
    uint256 internal supplyIndex;
    uint256 internal demandIndex;

    // Enum
    enum EnergyState {
        Register, // 0
        Injected, // 1
        Board, // 2
        Match, // 3
        Purchased // 4
    }

    // Structures
    struct EnergyOwnership {
        address addrOwner;
        uint256 energyAmount;
        uint256 energyState;
        uint256 timestamp;
    }
    struct Supply {
        address addrProsumer;
        uint256 energySupplied;
    }
    struct Demand {
        address addrConsumer;
        uint256 energyDemanded;
    }
    struct EnergyMatched {
        address addrProsumer;
        address addrConsumer;
        uint256 energyAmount;
        uint256 timestamp;
    }

    // Mappings
    mapping(address => uint256) internal addrIndex;

    // Arrays
    EnergyOwnership[][] internal energys;
    EnergyOwnership[] energy;
    Supply[] internal supplies;
    Demand[] internal demands;
    EnergyMatched[] internal matches;

    // Events
    event EnergyMatchedCheck(
        address addrProsumer,
        address addrConsumer,
        uint256 value,
        uint256 timestamp
    );
    event EnergyCheck(
        address addrOwner,
        uint256 energyAmount,
        uint256 energyState,
        uint256 timestamp
    );
    event RequestCheck(address addr, uint256 amount);
    event RoundStart(uint256 stime, uint256 etime);
    event Gen(uint256 gen);

    // Constructor
    constructor(NRGToken _tokenContract) {
        tokenContract = _tokenContract;
        DSO = msg.sender;
    }

    // Functions

    // Round Start
    function roundStart() public {
        if (msg.sender != DSO) revert();
        uint256 stime = block.timestamp;
        etime = stime + 1 hours;
        totalEnergyDemanded = 0;
        totalEnergySupplied = 0;
        emit RoundStart(stime, etime);
    }

    // Register
    function register() public {
        addrIndex[msg.sender] = totalUsers;
        EnergyOwnership memory _energy = EnergyOwnership(
            msg.sender,
            0,
            uint256(EnergyState.Register),
            block.timestamp
        );
        energy.push(_energy);
        energys.push(energy);

        emit EnergyCheck(
            energys[totalUsers][0].addrOwner,
            energys[totalUsers][0].energyAmount,
            energys[totalUsers][0].energyState,
            energys[totalUsers][0].timestamp
        );
        totalUsers++;
        delete energy;
    }

    // Inject Energy (Ei)
    function inject(address _owner, uint256 _amount) public {
        if (msg.sender != DSO) revert();

        EnergyOwnership memory _energy = EnergyOwnership(
            _owner,
            _amount,
            uint256(EnergyState.Injected),
            block.timestamp
        );
        uint256 i = addrIndex[_owner];
        energys[i].push(_energy);
        uint256 j = energys[i].length - 1;

        emit EnergyCheck(
            energys[i][j].addrOwner,
            energys[i][j].energyAmount,
            energys[i][j].energyState,
            energys[i][j].timestamp
        );

        // Aggregation
        for (uint256 k = j; k > 1; k--) {
            if (energys[i][k].energyState == uint256(EnergyState.Injected)) {
                energys[i][1].energyAmount += energys[i][k].energyAmount;
                energys[i][1].timestamp = block.timestamp;
                delete energys[i][k];
            }
        }
        emit Gen(0);
    }

    // Request to sell amount of intent to sell (Si)
    function requestSell(uint256 _amount) public {
        uint256 i = addrIndex[msg.sender];
        uint256 j = energys[i].length - 1;

        // Aggregation
        for (uint256 k = j; k > 1; k--) {
            if (energys[i][k].energyState == uint256(EnergyState.Injected)) {
                energys[i][1].energyAmount += energys[i][k].energyAmount;
                energys[i][1].timestamp = block.timestamp;
                delete energys[i][k];
            }
        }

        if (energys[i][1].energyAmount < _amount) revert();
        if (block.timestamp > etime) revert();

        EnergyOwnership memory _energy = EnergyOwnership(
            msg.sender,
            _amount,
            uint256(EnergyState.Board),
            block.timestamp
        );
        energys[i].push(_energy);
        energys[i][1].energyAmount -= _amount;

        Supply memory _supply = Supply(msg.sender, _amount);
        supplies.push(_supply);
        supplyIndex++;
        totalEnergySupplied += _amount;

        emit RequestCheck(msg.sender, _amount);
    }

    // Request to buy amount of intent to buy (Di)
    function requestBuy(uint256 _amount) public {
        if (_amount == 0) revert();
        if (_amount * MAX_ENERGYPRICE > tokenContract.balanceOf(msg.sender))
            revert();
        if (block.timestamp > etime) revert();

        tokenContract.decreaseApproval(
            DSO,
            tokenContract.balanceOf(msg.sender)
        );

        Demand memory demand = Demand(msg.sender, _amount);
        demands.push(demand);
        demandIndex++;
        totalEnergyDemanded += _amount;
        tokenContract.approve(DSO, _amount * MAX_ENERGYPRICE);

        emit RequestCheck(msg.sender, _amount);
    }

    // Match
    function matching() public {
        etime = block.timestamp;
        // q - Demand/Supply Ratio
        uint256 q = 1;
        uint256 tradedSupplyIndex;
        uint256 tradedDemandIndex;

        if (totalEnergySupplied > totalEnergyDemanded) {
            q = (totalEnergyDemanded * 100) / totalEnergySupplied;

            // Setting matched (actually sold) energy (Smi)
            for (uint256 i = 0; i < supplyIndex; i++) {
                supplies[i].energySupplied =
                    (supplies[i].energySupplied * q) /
                    100;

                uint256 addr_i = addrIndex[supplies[i].addrProsumer];
                uint256 j = energys[addr_i].length - 1;
                energys[addr_i][1].energyAmount +=
                    energys[addr_i][j].energyAmount -
                    (energys[addr_i][j].energyAmount * q) /
                    100;
                energys[addr_i][1].timestamp = block.timestamp;
                energys[addr_i][j].energyAmount =
                    (energys[addr_i][j].energyAmount * q) /
                    100;
                energys[addr_i][j].energyState = uint256(EnergyState.Match);
            }
        } else if (totalEnergySupplied < totalEnergyDemanded) {
            q = (totalEnergySupplied * 100) / totalEnergyDemanded;

            // Setting matched (actually bought) energy (Dmi)
            for (uint256 i = 0; i < demandIndex; i++) {
                demands[i].energyDemanded =
                    (demands[i].energyDemanded * q) /
                    100;
            }
        }

        // Getting energySupplied and energyDemanded
        uint256 sellingAmount = supplies[tradedSupplyIndex].energySupplied;
        uint256 buyingAmount = demands[tradedDemandIndex].energyDemanded;

        // Matching
        do {
            if (sellingAmount > buyingAmount) {
                // Matching buyingAmount of energy
                sellingAmount -= buyingAmount;
                EnergyMatched memory _match = EnergyMatched(
                    supplies[tradedSupplyIndex].addrProsumer,
                    demands[tradedDemandIndex].addrConsumer,
                    buyingAmount,
                    block.timestamp
                );
                matches.push(_match);
                emit EnergyMatchedCheck(
                    _match.addrProsumer,
                    _match.addrConsumer,
                    _match.energyAmount,
                    _match.timestamp
                );
                tradedDemandIndex++;
                if (tradedDemandIndex >= demandIndex) break;
                buyingAmount = demands[tradedDemandIndex].energyDemanded;
            } else if (sellingAmount < buyingAmount) {
                // Matching sellingAmount of energy
                buyingAmount -= sellingAmount;
                EnergyMatched memory _match = EnergyMatched(
                    supplies[tradedSupplyIndex].addrProsumer,
                    demands[tradedDemandIndex].addrConsumer,
                    sellingAmount,
                    block.timestamp
                );
                matches.push(_match);
                emit EnergyMatchedCheck(
                    _match.addrProsumer,
                    _match.addrConsumer,
                    _match.energyAmount,
                    _match.timestamp
                );
                tradedSupplyIndex++;
                if (tradedSupplyIndex >= supplyIndex) break;
                sellingAmount = supplies[tradedSupplyIndex].energySupplied;
            } else {
                // Matching equal energy
                EnergyMatched memory _match = EnergyMatched(
                    supplies[tradedSupplyIndex].addrProsumer,
                    demands[tradedDemandIndex].addrConsumer,
                    sellingAmount,
                    block.timestamp
                );
                matches.push(_match);
                emit EnergyMatchedCheck(
                    _match.addrProsumer,
                    _match.addrConsumer,
                    _match.energyAmount,
                    _match.timestamp
                );
                tradedSupplyIndex++;
                tradedDemandIndex++;
                if (tradedSupplyIndex >= supplyIndex) break;
                if (tradedDemandIndex >= demandIndex) break;
                sellingAmount = supplies[tradedSupplyIndex].energySupplied;
                buyingAmount = demands[tradedDemandIndex].energyDemanded;
            }
        } while (true);

        for (uint256 i = 0; i < totalUsers; i++) {
            for (uint256 j = energys[i].length - 1; j > 1; j--) {
                if (energys[i][j].energyAmount == 0) delete energys[i][j];
            }
        }

        emit Gen(0);
    }

    // Trade
    function trade(uint256 _price) public {
        uint256 price = _price;

        for (uint256 i = 0; i < matches.length; i++) {
            tokenContract.transferFrom(
                matches[i].addrConsumer,
                matches[i].addrProsumer,
                matches[i].energyAmount * price
            );
            EnergyOwnership memory _energy = EnergyOwnership(
                matches[i].addrConsumer,
                matches[i].energyAmount,
                uint256(EnergyState.Purchased),
                block.timestamp
            );
            energys[addrIndex[matches[i].addrConsumer]].push(_energy);
        }
        delete matches;
        emit Gen(0);
    }
}
