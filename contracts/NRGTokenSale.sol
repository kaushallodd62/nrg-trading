// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./NRGToken.sol";

contract NRGTokenSale {
    // state variables
    address owner;
    NRGToken public tokenContract;
    uint256 public tokenPrice;
    uint256 public tokensSold;

    // events
    event Sell(address _buyer, uint256 _amount);

    // constructor
    constructor(NRGToken _tokenContract, uint256 _tokenPrice) {
        owner = msg.sender;
        tokenContract = _tokenContract;
        tokenPrice = _tokenPrice;
    }

    // functions
    function buyTokens(uint256 _numberOfTokens) public payable {
        require(msg.value == _numberOfTokens * tokenPrice);
        require(tokenContract.balanceOf(address(this)) >= _numberOfTokens);
        require(tokenContract.transfer(msg.sender, _numberOfTokens));
        tokensSold += _numberOfTokens;
        emit Sell(msg.sender, _numberOfTokens);
    }

    function endSale() public {
        require(msg.sender == owner);
        require(tokenContract.transfer(owner, tokenContract.balanceOf(address(this))));
        payable(owner).transfer(address(this).balance);
    }
}