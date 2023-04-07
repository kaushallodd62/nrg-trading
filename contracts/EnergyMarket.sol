// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Errors
error EnergyMarket__InsufficientBalance(uint256 balance, uint256 required);
error EnergyMarket__InsufficientAllowance(uint256 allowance, uint256 required);
error EnergyMarket__InvalidAddress(address addr);
error EnergyMarket__NotDSO();
error EnergyMarket__NotRegistered();
error EnergyMarket__InsufficientEnergyInjected(
    uint256 energyAmount,
    uint256 required
);
error EnergyMarket__OutsideRound();
error EnergyMarket__ZeroEnergyAmount();

/**
 * @title A smart contract for Energy Trading
 * @author Kaushal Lodd
 * @notice  This contract generates and controls circulation of NRGTokens for facilitating energy trading. It also simulates an energy market where users can register, prosumers can inject energy and supply energy, consumers can demand energy, and the energy market can match the prosumers and consumers based on their energy demands and supplies.
 * @dev This contract is deployed by the DSO who plays a crucial role in the energy market. The Matching algoritm matches the prosumers and consumers automatically.
 */
contract EnergyMarket {
    // State Variables
    string public constant NAME = "NRG Token";
    string public constant SYMBOL = "NRG";
    string public constant STANDARD = "NRG Token v1.0";
    uint8 public constant DECIMALS = 18;
    uint256 internal constant INITIAL_SUPPLY =
        10000000 * (10 ** uint256(DECIMALS));
    uint256 internal _totalSupply;
    address internal immutable DSO;

    // Mappings
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    // Events
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value,
        uint256 balanceOfSender,
        uint256 balanceOfReciever
    );
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    // Constructor
    constructor() {
        DSO = msg.sender;
        _totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(
            address(0),
            msg.sender,
            INITIAL_SUPPLY,
            balances[address(0)],
            balances[msg.sender]
        );
    }

    // Functions
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(
        address _to,
        uint256 _value
    ) public returns (bool success) {
        if (_to == address(0)) revert EnergyMarket__InvalidAddress(_to);
        if (_value > balances[msg.sender])
            revert EnergyMarket__InsufficientBalance({
                balance: balances[msg.sender],
                required: _value
            });
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(
            msg.sender,
            _to,
            _value,
            balances[msg.sender],
            balances[_to]
        );
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        if (_to == address(0)) revert EnergyMarket__InvalidAddress(_to);
        if (_value > balances[_from])
            revert EnergyMarket__InsufficientBalance({
                balance: balances[_from],
                required: _value
            });
        if (_value > allowed[_from][msg.sender])
            revert EnergyMarket__InsufficientAllowance({
                allowance: allowed[_from][msg.sender],
                required: _value
            });
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value, balances[_from], balances[_to]);
        return true;
    }

    function approve(
        address _spender,
        uint256 _value
    ) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(
        address _owner,
        address _spender
    ) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(
        address _spender,
        uint256 _addedValue
    ) public returns (bool success) {
        allowed[msg.sender][_spender] += _addedValue;
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    ) public returns (bool success) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue - _subtractedValue;
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    // State Variables
    uint256 public totalEnergySupplied;
    uint256 public totalEnergyDemanded;
    uint256 public totalUsers;
    uint256 internal etime;
    uint256 internal supplyIndex;
    uint256 internal demandIndex;
    uint256 public constant MAX_ENERGYPRICE = 500 * (10 ** uint256(DECIMALS));

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
    EnergyOwnership[][] public energys;
    EnergyOwnership[] internal energy;
    Supply[] public supplies;
    Demand[] public demands;
    EnergyMatched[] public matches;

    // Events
    event Gen(uint256 gen);
    event EnergyCheck(
        address addrOwner,
        uint256 energyAmount,
        uint256 energyState,
        uint256 timestamp
    );
    event RoundStart(uint256 stime, uint256 etime);
    event SellRequestCheck(address addr, uint256 amount);
    event BuyRequestCheck(address addr, uint256 amount);
    event EnergyMatchedCheck(
        address addrProsumer,
        address addrConsumer,
        uint256 value,
        uint256 timestamp
    );

    // Functions
    function getDSO() public view returns (address) {
        return DSO;
    }

    function roundStart() public {
        if (msg.sender != DSO) revert EnergyMarket__NotDSO();
        uint256 stime = block.timestamp;
        etime = stime + 1 hours;
        totalEnergyDemanded = 0;
        totalEnergySupplied = 0;
        emit RoundStart(stime, etime);
    }

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
        if (msg.sender != DSO) revert EnergyMarket__NotDSO();
        if (
            energys[addrIndex[_owner]][0].energyState !=
            uint256(EnergyState.Register)
        ) revert EnergyMarket__NotRegistered();

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
        if (j != 1) {
            energys[i][1].energyAmount += energys[i][j].energyAmount;
            energys[i][1].timestamp = block.timestamp;
            energys[i].pop();
        }
        emit Gen(0);
    }

    // Request to sell amount of intent to sell (Si)
    function requestSell(uint256 _amount) public {
        uint256 i = addrIndex[msg.sender];
        if (energys[i][1].energyAmount < _amount)
            revert EnergyMarket__InsufficientEnergyInjected({
                energyAmount: energys[i][1].energyAmount,
                required: _amount
            });
        if (block.timestamp > etime) revert EnergyMarket__OutsideRound();

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

        emit SellRequestCheck(msg.sender, _amount);
    }

    // Request to buy amount of intent to buy (Di)
    function requestBuy(uint256 _amount) public {
        if (_amount == 0) revert EnergyMarket__ZeroEnergyAmount();
        if (_amount * MAX_ENERGYPRICE > balanceOf(msg.sender))
            revert EnergyMarket__InsufficientBalance({
                balance: balanceOf(msg.sender),
                required: _amount * MAX_ENERGYPRICE
            });
        if (block.timestamp > etime) revert EnergyMarket__OutsideRound();

        uint256 i = addrIndex[msg.sender];
        EnergyOwnership memory _energy = EnergyOwnership(
            msg.sender,
            _amount,
            uint256(EnergyState.Board),
            block.timestamp
        );
        energys[i].push(_energy);

        Demand memory demand = Demand(msg.sender, _amount);
        demands.push(demand);
        demandIndex++;
        totalEnergyDemanded += _amount;

        decreaseApproval(DSO, balanceOf(msg.sender));
        approve(DSO, _amount * MAX_ENERGYPRICE);

        emit BuyRequestCheck(msg.sender, _amount);
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
                energys[addr_i][j].timestamp = block.timestamp;
            }
        } else if (totalEnergySupplied < totalEnergyDemanded) {
            q = (totalEnergySupplied * 100) / totalEnergyDemanded;

            // Setting matched (actually bought) energy (Dmi)
            for (uint256 i = 0; i < demandIndex; i++) {
                demands[i].energyDemanded =
                    (demands[i].energyDemanded * q) /
                    100;
                energys[addrIndex[demands[i].addrConsumer]][1]
                    .energyAmount = demands[i].energyDemanded;
                energys[addrIndex[demands[i].addrConsumer]][1]
                    .energyState = uint256(EnergyState.Match);
                energys[addrIndex[demands[i].addrConsumer]][1].timestamp = block
                    .timestamp;
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
                if (energys[i][j].energyAmount == 0) {
                    for (uint256 k = j; k < energys[i].length - 1; k++) {
                        energys[i][k] = energys[i][k + 1];
                    }
                    energys[i].pop();
                }
            }
        }

        emit Gen(0);
    }

    // Trade
    function trade(uint256 _price) public {
        if (msg.sender != DSO) revert EnergyMarket__NotDSO();
        uint256 price = _price;

        for (uint256 i = 0; i < matches.length; i++) {
            transferFrom(
                matches[i].addrConsumer,
                matches[i].addrProsumer,
                matches[i].energyAmount * price
            );
            energys[addrIndex[matches[i].addrConsumer]][1]
                .energyAmount = matches[i].energyAmount;
            energys[addrIndex[matches[i].addrConsumer]][1]
                .energyState = uint256(EnergyState.Purchased);
            energys[addrIndex[matches[i].addrConsumer]][1].timestamp = block
                .timestamp;
        }
        delete matches;
        emit Gen(0);
    }
}
