//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./NRGToken.sol";

contract Matching {
    
    // state variables
    NRGToken public tokenContract;
    uint256 public numberOfOffers;
    uint256 public numberOfDemands;
    
    // structures
    struct Offer {
        uint256 idOffer;
        address addrSeller;
        string nameSeller;
        uint256 energyOffered;
    }
    struct Demand {
        uint256 idDemand;
        address addrBuyer;
        string nameBuyer;
        uint256 energyDemanded;
    }
    
    // mappings
    mapping(uint256 => Demand) public demands;
    mapping(uint256 => Offer) public offers;
    
    // constructor
    constructor (NRGToken _tokenContract)  {
        numberOfOffers=0;
        numberOfDemands=0;
        tokenContract=_tokenContract;
    }
    
    // functions

    // Get the current user
    function getCurrentMatchingUser() public view returns (address) {
        return msg.sender;
    }
    
    // Producer places an offer
    function placeOffer (address _addrSeller, string memory _nameSeller, uint256 _energyOffered) public {
       Offer memory o;
       o.addrSeller=_addrSeller;
       o.nameSeller=_nameSeller;
       o.energyOffered=_energyOffered;
       o.idOffer= numberOfOffers;
       offers[numberOfOffers]=o;
       numberOfOffers++;
       
    } 
  
    // Consumer places a demand
    function placeDemand (address _addrBuyer, string memory _nameBuyer, uint256 _energyDemanded) public {
       Demand memory d;
       d.addrBuyer=_addrBuyer;
       d.nameBuyer=_nameBuyer;
       d.energyDemanded=_energyDemanded;
       d.idDemand= numberOfDemands;
       demands[numberOfDemands]=d;
       numberOfDemands++;
    }
    
    // Get the number of offers
    function getOffersLength() public view returns (uint256) {
        return(numberOfOffers);
    }
    
    // Get the number of demands
    function getDemandsLength() public view returns (uint256) {
        return(numberOfDemands);
    }

    // Get the offer by id
    function getOfferById(uint256 _id) public view returns (address, string memory, uint256){
        return (offers[_id].addrSeller, offers[_id].nameSeller, offers[_id].energyOffered);
    }
    
    // Get the demand by id
    function getDemandById(uint256 _id) public view returns (address, string memory, uint256){
        return (demands[_id].addrBuyer, demands[_id].nameBuyer, demands[_id].energyDemanded);
    }

    // Get all offers by address
    function getOffersByAddress(address _addr) public view returns (Offer[] memory) {
        Offer[] memory offersTab = new Offer[](numberOfOffers);
        uint256 j=0;
        
        for(uint i=0;i<numberOfOffers;i++){
            if(offers[i].addrSeller==_addr){
                offersTab[j]=offers[i];
                j++;
            }
        }
        return(offersTab);
    }

    // Get all demands by address
    function getDemandsByAddress(address _addr) public view returns (Demand[] memory) {
        Demand[] memory demandsTab = new Demand[](numberOfDemands);
        uint256 j=0;
        
        for(uint i=0;i<numberOfDemands;i++){
            if(demands[i].addrBuyer==_addr){
                demandsTab[j]=demands[i];
                j++;
            }
        }
        return(demandsTab);
    }
    
    // Get all offers
    function getAllOffers() public view returns (Offer[] memory) {
        Offer[] memory offersTab = new Offer[](numberOfOffers);
        
        for(uint i=0;i<numberOfOffers;i++){
            offersTab[i]=offers[i];
        }
        return(offersTab);
    }

    // Get all demands
    function getAllDemands() public view returns (Demand[] memory) {
        Demand[] memory demandsTab = new Demand[](numberOfDemands);
        
        for(uint i=0;i<numberOfDemands;i++){
            demandsTab[i]=demands[i];
        }
        return(demandsTab);
    }

    // Linkning the buyer and the seller
    function link(uint256 idOffer, address seller) public {
        require(offers[idOffer].addrSeller==seller);
        tokenContract.transferFrom(msg.sender, seller, offers[idOffer].energyOffered);
        delete offers[idOffer];
    }
}