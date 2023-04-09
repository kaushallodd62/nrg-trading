// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Errors
error EnergyMarket__InsufficientBalance(uint256 balance, uint256 required);
error EnergyMarket__InsufficientAllowance(uint256 allowance, uint256 required);
error EnergyMarket__InvalidAddress(address addr);
error EnergyMarket__Not_DSO();
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
 * @notice  This contract generates and controls circulation of NRGTokens for facilitating energy trading. It also simulates an energy market where users can register, prosumers can inject energy and supply energy, consumers can demand energy, and the energy market can match the prosumers and consumers based on their energy s_demands and s_supplies.
 * @dev This contract is deployed by the i_DSO who plays a crucial role in the energy market. The Matching algoritm s_matches the prosumers and consumers automatically.
 */
contract EnergyMarket {
    // State Variables
    string public constant NAME = "NRG Token";
    string public constant SYMBOL = "NRG";
    string public constant STANDARD = "NRG Token v1.0";
    uint8 public constant DECIMALS = 18;
    uint256 internal constant INITIAL_SUPPLY =
        10000000 * (10 ** uint256(DECIMALS));
    uint256 internal s_totalSupply;
    address internal immutable i_DSO;

    // Mappings
    mapping(address => uint256) internal s_balances;
    mapping(address => mapping(address => uint256)) internal s_allowed;

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
        i_DSO = msg.sender;
        s_totalSupply = INITIAL_SUPPLY;
        s_balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(
            address(0),
            msg.sender,
            INITIAL_SUPPLY,
            s_balances[address(0)],
            s_balances[msg.sender]
        );
    }

    // Functions
    function totalSupply() public view returns (uint256) {
        return s_totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return s_balances[_owner];
    }

    function transfer(
        address _to,
        uint256 _value
    ) public returns (bool success) {
        if (_to == address(0)) revert EnergyMarket__InvalidAddress(_to);
        if (_value > s_balances[msg.sender])
            revert EnergyMarket__InsufficientBalance({
                balance: s_balances[msg.sender],
                required: _value
            });
        s_balances[msg.sender] -= _value;
        s_balances[_to] += _value;
        emit Transfer(
            msg.sender,
            _to,
            _value,
            s_balances[msg.sender],
            s_balances[_to]
        );
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        if (_to == address(0)) revert EnergyMarket__InvalidAddress(_to);
        uint256 availBalance = s_balances[_from];
        uint256 availAllowance = s_allowed[_from][msg.sender];
        if (_value > availBalance)
            revert EnergyMarket__InsufficientBalance({
                balance: availBalance,
                required: _value
            });
        if (_value > availAllowance)
            revert EnergyMarket__InsufficientAllowance({
                allowance: availAllowance,
                required: _value
            });
        s_balances[_from] -= _value;
        s_balances[_to] += _value;
        s_allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value, s_balances[_from], s_balances[_to]);
        return true;
    }

    function approve(
        address _spender,
        uint256 _value
    ) public returns (bool success) {
        s_allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(
        address _owner,
        address _spender
    ) public view returns (uint256 remaining) {
        return s_allowed[_owner][_spender];
    }

    function increaseAllowance(
        address _spender,
        uint256 _addedValue
    ) public returns (bool success) {
        s_allowed[msg.sender][_spender] += _addedValue;
        emit Approval(msg.sender, _spender, s_allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseAllowance(
        address _spender,
        uint256 _subtractedValue
    ) public returns (bool success) {
        uint256 oldValue = s_allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            s_allowed[msg.sender][_spender] = 0;
        } else {
            s_allowed[msg.sender][_spender] = oldValue - _subtractedValue;
        }
        emit Approval(msg.sender, _spender, s_allowed[msg.sender][_spender]);
        return true;
    }

    // State Variables
    uint256 public s_totalEnergySupplied;
    uint256 public s_totalEnergyDemanded;
    uint256 public s_totalUsers;
    uint256 internal s_endTime;
    uint256 internal s_supplyIndex;
    uint256 internal s_demandIndex;
    uint256 public constant MAX_ENERGYPRICE = 500 * (10 ** uint256(DECIMALS));

    // Enum
    enum energyState {
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
    mapping(address => uint256) internal s_addrIndex;

    // Arrays
    EnergyOwnership[][] internal s_energys;
    EnergyOwnership[] internal s_energy;
    Supply[] public s_supplies;
    Demand[] public s_demands;
    EnergyMatched[] public s_matches;

    // Events
    event Gen(uint256 gen);
    event EnergyCheck(
        address addrOwner,
        uint256 energyAmount,
        uint256 energyState,
        uint256 timestamp
    );
    event RoundStart(uint256 startTime, uint256 endTime);
    event SellRequestCheck(address addr, uint256 amount);
    event BuyRequestCheck(address addr, uint256 amount);
    event EnergyMatchedCheck(
        address addrProsumer,
        address addrConsumer,
        uint256 value,
        uint256 timestamp
    );

    // Functions
    function geti_DSO() public view returns (address) {
        return i_DSO;
    }

    function roundStart() public {
        if (msg.sender != i_DSO) revert EnergyMarket__Not_DSO();
        uint256 startTime = block.timestamp;
        s_endTime = startTime + 1 hours;
        s_totalEnergyDemanded = 0;
        s_totalEnergySupplied = 0;
        emit RoundStart(startTime, s_endTime);
    }

    function register() public {
        uint256 userCount = s_totalUsers;
        s_addrIndex[msg.sender] = userCount;
        EnergyOwnership memory _energy = EnergyOwnership(
            msg.sender,
            0,
            uint256(energyState.Register),
            block.timestamp
        );
        s_energy.push(_energy);
        s_energys.push(s_energy);

        emit EnergyCheck(
            msg.sender,
            0,
            uint256(energyState.Register),
            _energy.timestamp
        );
        s_totalUsers++;
    }

    // Inject Energy (Ei)
    function inject(address _owner, uint256 _amount) public {
        if (msg.sender != i_DSO) revert EnergyMarket__Not_DSO();
        uint256 i = s_addrIndex[_owner];
        if (s_energys[i][0].energyState != uint256(energyState.Register))
            revert EnergyMarket__NotRegistered();

        EnergyOwnership memory _energy = EnergyOwnership(
            _owner,
            _amount,
            uint256(energyState.Injected),
            block.timestamp
        );
        s_energys[i].push(_energy);
        uint256 j = s_energys[i].length - 1;

        emit EnergyCheck(
            _owner,
            _amount,
            uint256(energyState.Injected),
            _energy.timestamp
        );

        // Aggregation
        if (j != 1) {
            s_energys[i][1].energyAmount += s_energys[i][j].energyAmount;
            s_energys[i][1].timestamp = block.timestamp;
            s_energys[i].pop();
        }
        emit Gen(0);
    }

    // Request to sell amount of intent to sell (Si)
    function requestSell(uint256 _amount) public {
        uint256 i = s_addrIndex[msg.sender];
        uint256 injectedEnergy = s_energys[i][1].energyAmount;
        if (injectedEnergy < _amount)
            revert EnergyMarket__InsufficientEnergyInjected({
                energyAmount: injectedEnergy,
                required: _amount
            });
        if (block.timestamp > s_endTime) revert EnergyMarket__OutsideRound();

        EnergyOwnership memory _energy = EnergyOwnership(
            msg.sender,
            _amount,
            uint256(energyState.Board),
            block.timestamp
        );
        s_energys[i].push(_energy);
        s_energys[i][1].energyAmount = injectedEnergy - _amount;

        Supply memory _supply = Supply(msg.sender, _amount);
        s_supplies.push(_supply);
        s_supplyIndex++;
        s_totalEnergySupplied += _amount;

        emit SellRequestCheck(msg.sender, _amount);
    }

    // Request to buy amount of intent to buy (Di)
    function requestBuy(uint256 _amount) public {
        if (_amount == 0) revert EnergyMarket__ZeroEnergyAmount();
        uint256 balance = balanceOf(msg.sender);
        uint256 maxPrice = _amount * MAX_ENERGYPRICE;
        if (maxPrice > balance)
            revert EnergyMarket__InsufficientBalance({
                balance: balance,
                required: maxPrice
            });
        if (block.timestamp > s_endTime) revert EnergyMarket__OutsideRound();

        uint256 i = s_addrIndex[msg.sender];
        EnergyOwnership memory _energy = EnergyOwnership(
            msg.sender,
            _amount,
            uint256(energyState.Board),
            block.timestamp
        );
        s_energys[i].push(_energy);

        Demand memory demand = Demand(msg.sender, _amount);
        s_demands.push(demand);
        s_demandIndex++;
        s_totalEnergyDemanded += _amount;

        decreaseAllowance(i_DSO, balance);
        approve(i_DSO, maxPrice);

        emit BuyRequestCheck(msg.sender, _amount);
    }

    // Match
    function matching() public {
        // Setting endTime of round to when the matching() function is called
        s_endTime = block.timestamp;

        // Local Variables for gas optimization
        uint256 totalSupplyOfEnergy = s_totalEnergySupplied;
        uint256 totalDemandOfEnergy = s_totalEnergyDemanded;
        uint256 supplyIndex = s_supplyIndex;
        uint256 demandIndex = s_demandIndex;

        // q - Demand/Supply Ratio
        uint256 q = 1;
        uint256 matchedSupplyIndex;
        uint256 matchedDemandIndex;

        if (totalSupplyOfEnergy > totalDemandOfEnergy) {
            q = (totalDemandOfEnergy * 100) / totalSupplyOfEnergy;

            // Setting matched (actually sold) energy (Smi)
            for (uint256 i = 0; i < supplyIndex; i++) {
                Supply memory _supply = s_supplies[i];
                s_supplies[i].energySupplied =
                    (_supply.energySupplied * q) /
                    100;

                uint256 addr_i = s_addrIndex[_supply.addrProsumer];
                uint256 j = s_energys[addr_i].length - 1;
                uint256 energyAmount = s_energys[addr_i][j].energyAmount;

                s_energys[addr_i][1].energyAmount +=
                    energyAmount -
                    (energyAmount * q) /
                    100;
                s_energys[addr_i][1].timestamp = block.timestamp;
                s_energys[addr_i][j].energyAmount = (energyAmount * q) / 100;
                s_energys[addr_i][j].energyState = uint256(energyState.Match);
                s_energys[addr_i][j].timestamp = block.timestamp;
            }
        } else if (totalSupplyOfEnergy < totalDemandOfEnergy) {
            q = (totalSupplyOfEnergy * 100) / totalDemandOfEnergy;

            // Setting matched (actually bought) energy (Dmi)
            for (uint256 i = 0; i < demandIndex; i++) {
                Demand memory _demand = s_demands[i];
                uint256 addr_i = s_addrIndex[_demand.addrConsumer];
                s_demands[i].energyDemanded =
                    (_demand.energyDemanded * q) /
                    100;
                s_energys[addr_i][1].energyAmount = _demand.energyDemanded;
                s_energys[addr_i][1].energyState = uint256(energyState.Match);
                s_energys[addr_i][1].timestamp = block.timestamp;
            }
        }

        // Getting each supply and demand to match
        Supply memory supply = s_supplies[matchedSupplyIndex];
        Demand memory demand = s_demands[matchedDemandIndex];

        // Matching
        do {
            if (supply.energySupplied > demand.energyDemanded) {
                // Matching demand.energyDemanded of energy
                supply.energySupplied -= demand.energyDemanded;
                EnergyMatched memory _match = EnergyMatched(
                    supply.addrProsumer,
                    demand.addrConsumer,
                    demand.energyDemanded,
                    block.timestamp
                );
                s_matches.push(_match);
                emit EnergyMatchedCheck(
                    _match.addrProsumer,
                    _match.addrConsumer,
                    _match.energyAmount,
                    _match.timestamp
                );
                matchedDemandIndex++;
                if (matchedDemandIndex >= demandIndex) break;
                demand = s_demands[matchedDemandIndex];
            } else if (supply.energySupplied < demand.energyDemanded) {
                // Matching supply.energySupplied of energy
                demand.energyDemanded -= supply.energySupplied;
                EnergyMatched memory _match = EnergyMatched(
                    supply.addrProsumer,
                    demand.addrConsumer,
                    supply.energySupplied,
                    block.timestamp
                );
                s_matches.push(_match);
                emit EnergyMatchedCheck(
                    _match.addrProsumer,
                    _match.addrConsumer,
                    _match.energyAmount,
                    _match.timestamp
                );
                matchedSupplyIndex++;
                if (matchedSupplyIndex >= supplyIndex) break;
                supply = s_supplies[matchedSupplyIndex];
            } else {
                // Matching equal energy
                EnergyMatched memory _match = EnergyMatched(
                    supply.addrProsumer,
                    demand.addrConsumer,
                    supply.energySupplied,
                    block.timestamp
                );
                s_matches.push(_match);
                emit EnergyMatchedCheck(
                    _match.addrProsumer,
                    _match.addrConsumer,
                    _match.energyAmount,
                    _match.timestamp
                );
                matchedSupplyIndex++;
                matchedDemandIndex++;
                if (matchedSupplyIndex >= supplyIndex) break;
                if (matchedDemandIndex >= demandIndex) break;
                supply = s_supplies[matchedSupplyIndex];
                demand = s_demands[matchedDemandIndex];
            }
        } while (true);

        uint256 userCount = s_totalUsers;
        for (uint256 i = 0; i < userCount; i++) {
            uint256 maxLen = s_energys[i].length;
            for (uint256 j = maxLen - 1; j > 1; j--) {
                if (s_energys[i][j].energyAmount == 0) {
                    for (uint256 k = j; k < maxLen - 1; k++) {
                        s_energys[i][k] = s_energys[i][k + 1];
                    }
                    s_energys[i].pop();
                }
            }
        }

        emit Gen(0);
    }

    // Trade
    function trade(uint256 _price) public {
        if (msg.sender != i_DSO) revert EnergyMarket__Not_DSO();
        uint256 price = _price;

        uint256 matchesLen = s_matches.length;
        for (uint256 i = 0; i < matchesLen; i++) {
            EnergyMatched memory _match = s_matches[i];
            uint256 index = s_addrIndex[_match.addrConsumer];
            transferFrom(
                _match.addrConsumer,
                _match.addrProsumer,
                _match.energyAmount * price
            );
            s_energys[index][1].energyAmount = _match.energyAmount;
            s_energys[index][1].energyState = uint256(energyState.Purchased);
            s_energys[index][1].timestamp = block.timestamp;
        }

        delete s_matches;
        emit Gen(0);
    }
}
