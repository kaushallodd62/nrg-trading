//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./NRG.sol";

contract Matching {
    
    uint256 public valueOneToken;
    address public buyer;
    uint256 public amountTokens;
    address public coinAddr;
    uint256 public numberOffers;
    uint256 public numberDemands;
    
    struct Offer {
     uint256 idOffer;
     address addrSeller;
     string nameSeller;
     uint256 unitPrice;
     uint256 tokenNumber;
     string debut;
     string end;
    }
    
    struct Demand {
     uint256 idDemand;
     address addrBuyer;
     string nameBuyer;
     uint256 maxUnitPrice;
     string debut;
     string end;
    }
    
    mapping(uint256 => Demand) public demands;
    mapping(uint256 => Offer) public offers;
    
    constructor ()  {
        numberOffers=0;
        numberDemands=0;
    }
    
    // getCurrentUser
    function getCurrentMatchingUser() public view returns (address) {
        return msg.sender;
    }   
    
    // TokenValue
    function setTokenValue(uint256 _valueOneToken) public {
        valueOneToken=_valueOneToken;
    }

    function getTokenValue() public view returns (uint256) {
        return(valueOneToken);
    }
    
    // Set the address of the token in NRG contract
    function setCoinAddr (address _addr) public {
        coinAddr=_addr;
    }
    
    // Verifying that the buyer has enough funds to buy the tokens
    modifier hasEther {
        require(buyer.balance > amountTokens*valueOneToken);
        _;
    }
  
    // Seller sells token and buyer recieves token
    function receiveNRG(address _seller) hasEther public returns (bool) {
            ERC20 _coin = ERC20(coinAddr);
            _coin.transferFrom(_seller, msg.sender, amountTokens);
            return true;
    }
    
    // Producer places an offer
    function placeOffer (address _addrSeller,string memory _nameSeller,uint256 _unitPrice,uint256 _tokenNumber,string memory _debut,string memory _end) public {
       Offer memory o;
       o.addrSeller=_addrSeller;
       o.nameSeller=_nameSeller;
       o.unitPrice=_unitPrice;
       o.tokenNumber=_tokenNumber;
       o.debut=_debut;
       o.end=_end;
       o.idOffer= numberOffers;
       offers[numberOffers]=o;
       numberOffers++;
       
    } 
  
    // Consumer places a demand
    function placeDemand (address _addrBuyer,string memory _nameBuyer,uint256 _maxUnitPrice,string memory _debut,string memory _end) public {
       Demand memory d;
       d.idDemand=numberDemands;
       d.addrBuyer=_addrBuyer;
       d.nameBuyer=_nameBuyer;
       d.maxUnitPrice=_maxUnitPrice;
       d.debut=_debut;
       d.end=_end;
       demands[numberDemands]=d;
       numberDemands++;
    } 
    
    // Get the number of offers
    function getOffersLength() public view returns (uint256) {
        return(numberOffers);
    }
    
    // Get the number of demands
    function getDemandsLength() public view returns (uint256) {
        return(numberDemands);
    }
    
    // Get the offer by address
    function getOfferByAddr(address addr) public view returns (address, string memory, uint256, uint256, string memory, string memory){
        uint ind;
        for(uint i=0; i<numberOffers; i++) {
            if(offers[i].addrSeller==addr){
                ind = i;
                break;
            }
        }
        return (offers[ind].addrSeller,offers[ind].nameSeller,offers[ind].unitPrice,offers[ind].tokenNumber,offers[ind].debut,offers[ind].end);
    }

    // Get the demand by address
    function getDemandByAddr(address addr) public view returns (address, string memory, uint256, string memory,string memory){
        uint ind;
        for(uint i=0; i<numberDemands; i++){
            if(demands[i].addrBuyer==addr){
                ind = i;
                break;
            }
        }
        return (demands[ind].addrBuyer,demands[ind].nameBuyer,demands[ind].maxUnitPrice,demands[ind].debut,demands[ind].end);
    }

    // Get the offer by id
    function getOfferById (uint256 _id) public view returns (address,string memory,uint256,uint256,string memory,string memory){
        return (offers[_id].addrSeller,offers[_id].nameSeller,offers[_id].unitPrice,offers[_id].tokenNumber,offers[_id].debut,offers[_id].end);
    }
    
    // Get the demand by id
    function getDemandById (uint256 _id) public view returns (address,string memory,uint256,string memory,string memory){
        return (demands[_id].addrBuyer,demands[_id].nameBuyer,demands[_id].maxUnitPrice,demands[_id].debut,demands[_id].end);
    }

    // Linkning the buyer and the seller
    function link(uint256 idOffer, address Buyer, address Seller, address NrgAddr) public {
        this.setCoinAddr(NrgAddr);
        ERC20 _coin = ERC20(coinAddr);
        _coin.transferFrom(Seller,Buyer,offers[idOffer].tokenNumber);
        delete offers[idOffer];
    }
    
    // Get all offers
    function getAllOffers() public view returns (Offer[] memory) {
        Offer[] memory offersTab = new Offer[](numberOffers);
        
        for(uint i=0;i<numberOffers;i++){
            offersTab[i]=offers[i];
        }
        return(offersTab);
    }

    // Get all demands
    function getAllDemands() public view returns (Demand[] memory) {
        Demand[] memory demandsTab = new Demand[](numberDemands);
        
        for(uint i=0;i<numberDemands;i++){
            demandsTab[i]=demands[i];
        }
        return(demandsTab);
    }
}