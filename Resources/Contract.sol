// SPDX-License-Identifier: MIT
pragma solidity ^0.5.1;

library SafeMath {
    function mul(uint256 a, uint256 b) internal returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        if (c / a != b) revert();
        return c;
    }

    function div(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal returns (uint256) {
        if (a < b) revert();
        return a - b;
    }

    function add(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        if (a >= c) revert();
        return c;
    }
}

contract token {
    // Events
    event Result(
        address from,
        address to,
        uint256 value,
        uint256 bos,
        uint256 bor
    );
    event energyshow(address from, address to, uint256 value);
    event energycheck(address owner, uint256 amount, uint state, uint bidtime);
    event requestchck(address _add, uint256 amount);
    event gen(uint256 o);
    event start(uint256 stime, uint256 etime);

    using SafeMath for uint256;
    mapping(address => uint256) balances;
    address DSO;
    uint256 _totalSupply;

    function totalSupply() public returns (uint256) {
        return _totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        if (_to == address(0)) revert();
        if (_value > balances[msg.sender]) revert();
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Result(
            msg.sender,
            _to,
            _value,
            balances[msg.sender],
            balances[_to]
        );
        return true;
    }

    function balanceOf(address _owner) public returns (uint256 balance) {
        return balances[_owner];
    }

    event Approval(address owner, address spender, uint256 value);
    mapping(address => mapping(address => uint256)) internal allowed;

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        if (_to == address(0)) revert();
        if (_value > balances[_from]) revert();
        if (_value > allowed[_from][msg.sender]) revert();
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Result(_from, _to, _value, balances[_from], balances[_to]);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(
        address _owner,
        address _spender
    ) public returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(
        address _spender,
        uint256 _addedValue
    ) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(
            _addedValue
        );
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    ) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    string public constant name = "EnergyToken";
    string public constant symbol = "ETK";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY =
        10000000 * (10 ** uint256(decimals));

    function EnergyToken() public {
        _totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Result(
            address(0),
            msg.sender,
            INITIAL_SUPPLY,
            balances[address(0)],
            balances[msg.sender]
        );
        DSO = msg.sender;
        emit gen(0);
    }

    uint256 energyprice_max = 555;
    uint256 totalsell = 0;
    uint256 totalbuy = 0;
    struct energy {
        address owner;
        uint256 amount;
        uint256 state;
        uint256 bidtime;
    }
    mapping(address => uint256) add_index;
    uint256 total_people = 0;
    energy[][] energys;
    energy[] energys_tmp_arr;
    struct selling {
        address seller;
        uint256 sellingamount;
    }
    selling[] sellings;
    uint256 index_sell = 0;
    struct buying {
        address buyer;
        uint256 buyingamount;
    }
    buying[] buyings;
    uint256 index_buy = 0;
    uint roundend;

    function register() public {
        add_index[msg.sender] = total_people;
        energy memory energy0 = energy(msg.sender, 0, 0, now);
        energys_tmp_arr.push(energy0);
        energys.push(energys_tmp_arr);
        emit energycheck(
            energys[total_people][0].owner,
            energys[total_people][0].amount,
            energys[total_people][0].state,
            energys[total_people][0].bidtime
        );
        total_people++;
        delete energys_tmp_arr;
    }

    function roundstart() public {
        if (msg.sender != DSO) revert();
        uint t = 1 hours;
        roundend = t + now;
        totalbuy = 0;
        totalsell = 0;
        emit start(now, roundend);
    }

    function inject(address _owner, uint256 _amount) public {
        uint add = add_index[_owner];
        if (msg.sender != DSO) revert();
        energy memory energy_tmp = energy(_owner, _amount, 1, now);
        energys[add].push(energy_tmp);
        uint la_num = energys[add].length - 1;
        emit energycheck(
            energys[add][la_num].owner,
            energys[add][la_num].amount,
            energys[add][la_num].state,
            energys[add][la_num].bidtime
        );
        delete energys_tmp_arr;
        uint i = add;
        uint j;
        for (j = energys[i].length - 1; j > 1; j--) {
            if (energys[i][j].state == 1) {
                energys[i][1].amount += energys[i][j].amount;
                energys[i][1].bidtime = now;
                delete energys[i][j];
            }
        }
        emit gen(0);
    }

    function requestsell(uint256 _amount) public {
        uint i = add_index[msg.sender];
        uint j;
        for (j = energys[i].length - 1; j > 1; j--) {
            if (energys[i][j].state == 1) {
                energys[i][1].amount += energys[i][j].amount;
                energys[i][1].bidtime = now;
                delete energys[i][j];
            }
        }
        if (energys[i][1].amount < _amount) revert();
        if (now > roundend) revert();
        energy memory energy_tmp = energy(msg.sender, _amount, 2, now);
        energys[i].push(energy_tmp);
        energys[i][1].amount -= _amount;
        selling memory sell = selling(msg.sender, _amount);
        sellings.push(sell);
        emit requestchck(msg.sender, _amount);
        index_sell++;
        totalsell += _amount;
    }

    function requestbuy(uint256 _amount) public {
        if (_amount == 0) revert();
        if (_amount * energyprice_max > balances[msg.sender]) revert();
        decreaseApproval(DSO, balances[msg.sender]);
        buying memory buy = buying(msg.sender, _amount);
        buyings.push(buy);
        approve(DSO, _amount * energyprice_max);
        index_buy++;
        totalbuy += _amount;
        if (now > roundend) revert();
        emit requestchck(msg.sender, _amount);
    }

    struct energy_matched {
        address prosumer;
        address consumer;
        uint256 amount;
        uint256 bidtime;
    }
    energy_matched[] energy_matches;

    function matching() public {
        roundend = now;
        uint256 p = 1;
        uint256 index_sell_trd = 0;
        uint256 index_buy_trd = 0;
        uint i = 0;
        uint j = 0;
        if (totalsell > totalbuy) {
            p = (totalbuy * 100) / totalsell;
            for (i = 0; i < index_sell; i++) {
                sellings[i].sellingamount =
                    (sellings[i].sellingamount * p) /
                    100;
                j = add_index[sellings[i].seller];
                energys[j][1].amount +=
                    energys[j][energys[j].length - 1].amount -
                    (energys[j][energys[j].length - 1].amount * p) /
                    100;
                energys[j][1].bidtime = now;
                energys[j][energys[j].length - 1].amount =
                    (energys[j][energys[j].length - 1].amount * p) /
                    100;
                energys[j][energys[j].length - 1].state = 3;
            }
            uint256 sellingamount_tmp = sellings[index_sell_trd].sellingamount;
            uint256 buyingamount_tmp = buyings[index_buy_trd].buyingamount;
            do {
                if (sellingamount_tmp > buyingamount_tmp) {
                    sellingamount_tmp -= buyingamount_tmp;
                    energy_matched memory energy_mat_tm = energy_matched(
                        sellings[index_sell_trd].seller,
                        buyings[index_buy_trd].buyer,
                        buyingamount_tmp,
                        now
                    );
                    energy_matches.push(energy_mat_tm);
                    emit energyshow(
                        sellings[index_sell_trd].seller,
                        buyings[index_buy_trd].buyer,
                        buyingamount_tmp
                    );
                    index_buy_trd++;
                    if (index_buy_trd >= index_buy) break;
                    buyingamount_tmp = buyings[index_buy_trd].buyingamount;
                } else if (sellingamount_tmp < buyingamount_tmp) {
                    buyingamount_tmp -= sellingamount_tmp;
                    energy_matched memory energy_mat_tm = energy_matched(
                        sellings[index_sell_trd].seller,
                        buyings[index_buy_trd].buyer,
                        sellingamount_tmp,
                        now
                    );
                    energy_matches.push(energy_mat_tm);
                    emit energyshow(
                        sellings[index_sell_trd].seller,
                        buyings[index_buy_trd].buyer,
                        sellingamount_tmp
                    );
                    index_sell_trd++;
                    if (index_sell_trd >= index_sell) break;
                    sellingamount_tmp = sellings[index_sell_trd].sellingamount;
                } else {
                    energy_matched memory energy_mat_tm = energy_matched(
                        sellings[index_sell_trd].seller,
                        buyings[index_buy_trd].buyer,
                        sellingamount_tmp,
                        now
                    );
                    energy_matches.push(energy_mat_tm);
                    emit energyshow(
                        sellings[index_sell_trd].seller,
                        buyings[index_buy_trd].buyer,
                        buyingamount_tmp
                    );
                    index_sell_trd++;
                    index_buy_trd++;
                    if (index_buy_trd >= index_buy) break;
                    if (index_sell_trd >= index_sell) break;
                    buyingamount_tmp = buyings[index_buy_trd].buyingamount;
                    sellingamount_tmp = sellings[index_sell_trd].sellingamount;
                }
            } while (true);
        } else if (totalsell < totalbuy) {
            p = (totalsell * 100) / totalbuy;
            for (i = 0; i < index_buy; i++) {
                buyings[i].buyingamount = (buyings[i].buyingamount * p) / 100;
            }
            uint256 sellingamount_tmp = sellings[index_sell_trd].sellingamount;
            uint256 buyingamount_tmp = buyings[index_buy_trd].buyingamount;
            do {
                if (sellingamount_tmp > buyingamount_tmp) {
                    sellingamount_tmp -= buyingamount_tmp;
                    energy_matched memory energy_mat_tm = energy_matched(
                        sellings[index_sell_trd].seller,
                        buyings[index_buy_trd].buyer,
                        buyingamount_tmp,
                        now
                    );
                    emit energyshow(
                        sellings[index_sell_trd].seller,
                        buyings[index_buy_trd].buyer,
                        buyingamount_tmp
                    );
                    energy_matches.push(energy_mat_tm);
                    index_buy_trd++;
                    if (index_buy_trd >= index_buy) break;
                    buyingamount_tmp = buyings[index_buy_trd].buyingamount;
                } else if (sellingamount_tmp < buyingamount_tmp) {
                    buyingamount_tmp -= sellingamount_tmp;
                    energy_matched memory energy_mat_tm = energy_matched(
                        sellings[index_sell_trd].seller,
                        buyings[index_buy_trd].buyer,
                        sellingamount_tmp,
                        now
                    );
                    energy_matches.push(energy_mat_tm);
                    emit energyshow(
                        sellings[index_sell_trd].seller,
                        buyings[index_buy_trd].buyer,
                        sellingamount_tmp
                    );
                    index_sell_trd++;
                    if (index_sell_trd >= index_sell) break;
                    sellingamount_tmp = sellings[index_sell_trd].sellingamount;
                } else {
                    energy_matched memory energy_mat_tm = energy_matched(
                        sellings[index_sell_trd].seller,
                        buyings[index_buy_trd].buyer,
                        sellingamount_tmp,
                        now
                    );
                    energy_matches.push(energy_mat_tm);
                    emit energyshow(
                        sellings[index_sell_trd].seller,
                        buyings[index_buy_trd].buyer,
                        buyingamount_tmp
                    );
                    index_sell_trd++;
                    index_buy_trd++;
                    if (index_buy_trd >= index_buy) break;
                    if (index_sell_trd >= index_sell) break;
                    buyingamount_tmp = buyings[index_buy_trd].buyingamount;
                    sellingamount_tmp = sellings[index_sell_trd].sellingamount;
                }
            } while (true);
        } else if (totalbuy == totalsell) {
            uint256 sellingamount_tmp = sellings[index_sell_trd].sellingamount;
            uint256 buyingamount_tmp = buyings[index_buy_trd].buyingamount;
            do {
                if (sellingamount_tmp > buyingamount_tmp) {
                    sellingamount_tmp -= buyingamount_tmp;
                    energy_matched memory energy_mat_tm = energy_matched(
                        sellings[index_sell_trd].seller,
                        buyings[index_buy_trd].buyer,
                        buyingamount_tmp,
                        now
                    );
                    energy_matches.push(energy_mat_tm);
                    emit energyshow(
                        sellings[index_sell_trd].seller,
                        buyings[index_buy_trd].buyer,
                        buyingamount_tmp
                    );
                    index_buy_trd++;
                    if (index_buy_trd >= index_buy) break;
                    buyingamount_tmp = buyings[index_buy_trd].buyingamount;
                } else if (sellingamount_tmp < buyingamount_tmp) {
                    buyingamount_tmp -= sellingamount_tmp;
                    energy_matched memory energy_mat_tm = energy_matched(
                        sellings[index_sell_trd].seller,
                        buyings[index_buy_trd].buyer,
                        sellingamount_tmp,
                        now
                    );
                    energy_matches.push(energy_mat_tm);
                    emit energyshow(
                        sellings[index_sell_trd].seller,
                        buyings[index_buy_trd].buyer,
                        sellingamount_tmp
                    );
                    index_sell_trd++;
                    if (index_sell_trd > index_sell) break;
                    sellingamount_tmp = sellings[index_sell_trd].sellingamount;
                } else {
                    energy_matched memory energy_mat_tm = energy_matched(
                        sellings[index_sell_trd].seller,
                        buyings[index_buy_trd].buyer,
                        sellingamount_tmp,
                        now
                    );
                    energy_matches.push(energy_mat_tm);
                    emit energyshow(
                        sellings[index_sell_trd].seller,
                        buyings[index_buy_trd].buyer,
                        buyingamount_tmp
                    );
                    index_sell_trd++;
                    index_buy_trd++;
                    if (index_buy_trd >= index_buy) break;
                    if (index_sell_trd >= index_sell) break;
                    buyingamount_tmp = buyings[index_buy_trd].buyingamount;
                    sellingamount_tmp = sellings[index_sell_trd].sellingamount;
                }
            } while (true);
        }
        for (i = 0; i < total_people; i++) {
            for (j = energys[i].length - 1; j > 1; j--) {
                if (energys[i][j].amount == 0) delete energys[i][j];
            }
        }
        emit gen(0);
    }

    function trade(uint256 _price) public {
        uint256 price = _price;
        uint256 i;
        for (i = 0; i < energy_matches.length; i++) {
            transferFrom(
                energy_matches[i].consumer,
                energy_matches[i].prosumer,
                energy_matches[i].amount * price
            );
            emit energyshow(
                energy_matches[i].prosumer,
                energy_matches[i].consumer,
                energy_matches[i].amount
            );
            energy memory energy_temp = energy(
                energy_matches[i].consumer,
                energy_matches[i].amount,
                4,
                now
            );
            energys[add_index[energy_matches[i].consumer]].push(energy_temp);
        }
        delete energy_matches;
        emit gen(0);
    }
}
