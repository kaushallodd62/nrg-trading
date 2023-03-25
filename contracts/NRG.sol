//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


library SafeMath {
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}


contract ERC20 is IERC20 {
    
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    uint256 private _totalSupply;
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        //_approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }
    
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0));
        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }
}


contract ERC20Detailed is IERC20, ERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory __name, string memory __symbol, uint8 __decimals) {
        _name = __name;
        _symbol = __symbol;
        _decimals = __decimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// NRG Token contract. Deploy to create token and get initial supply of token
contract NRG is ERC20, ERC20Detailed {
    
    uint8 public constant DECIMALS = 0;
    uint256 public constant INITIAL_SUPPLY = 100000000000000000 ;
    
    constructor () ERC20Detailed ("NRG", "nrg", DECIMALS) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
    
    function getContractaddress() public view returns(address){
        return (address(this));
    }
}