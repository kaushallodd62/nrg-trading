//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./NRGToken.sol";

contract EnergyMarket {
    
    // state variables
    NRGToken private tokenContract;
    uint256 private numberOfOffers;
    uint256 private numberOfDemands;
    address private owner;
    
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
    mapping(uint256 => Demand) private demands;
    mapping(uint256 => Offer) private offers;

    // events
    event OfferPlaced(uint256 idOffer, address addrSeller, string nameSeller, uint256 energyOffered);
    event DemandPlaced(uint256 idDemand, address addrBuyer, string nameBuyer, uint256 energyDemanded);
    event OfferRevoked(uint256 idOffer, address addrSeller, string nameSeller, uint256 energyOffered);
    event DemandRevoked(uint256 idDemand, address addrBuyer, string nameBuyer, uint256 energyDemanded);
    event DealMade(uint256 idOffer, uint256 idDemand, address addrSeller, string nameSeller, uint256 energyOffered, address addrBuyer, string nameBuyer, uint256 energyDemanded, uint256 NRGprice);
    
    // constructor
    constructor (NRGToken _tokenContract)  {
        numberOfOffers=0;
        numberOfDemands=0;
        tokenContract=_tokenContract;
        owner=msg.sender;
    }

    // Get the current user
    function getCurrentUser() public view returns (address) {
        return msg.sender;
    }
    
    // Producer places an offer
    function placeOffer (address _addrSeller, string memory _nameSeller, uint256 _energyOffered) public {
        require(msg.sender == _addrSeller, "Offer can be placed only by the user calling this function");
        require(_energyOffered > 0, "Energy offered must be greater than 0");
        Offer memory o;
        o.addrSeller=_addrSeller;
        o.nameSeller=_nameSeller;
        o.energyOffered=_energyOffered;
        o.idOffer= numberOfOffers;
        offers[numberOfOffers]=o;
        numberOfOffers++;
        emit OfferPlaced(o.idOffer, o.addrSeller, o.nameSeller, o.energyOffered);
    }
  
    // Consumer places a demand
    function placeDemand (address _addrBuyer, string memory _nameBuyer, uint256 _energyDemanded) public {
        require(msg.sender == _addrBuyer, "Demand can be placed only by the user calling this function");
        require(_energyDemanded > 0, "Energy demanded must be greater than 0");
        Demand memory d;
        d.addrBuyer=_addrBuyer;
        d.nameBuyer=_nameBuyer;
        d.energyDemanded=_energyDemanded;
        d.idDemand= numberOfDemands;
        demands[numberOfDemands]=d;
        numberOfDemands++;
        emit DemandPlaced(d.idDemand, d.addrBuyer, d.nameBuyer, d.energyDemanded);
    }

    // Revoke an offer
    function revokeOffer (uint256 _idOffer, address _addr) public {
        Offer memory o = offers[_idOffer];
        require(o.addrSeller == _addr, "Address provided doesn't match the address of the user who placed the offer");
        require(msg.sender == o.addrSeller || msg.sender == owner, "Offer can be revoked only by the user who placed it or by the owner of the contract");
        delete offers[_idOffer];
        for(uint i=_idOffer;i<numberOfOffers-1;i++){
            offers[i]=offers[i+1];
        }
        offers[numberOfOffers-1]=Offer(0,address(0),"",0);
        numberOfOffers--;
        emit OfferRevoked(_idOffer, o.addrSeller, o.nameSeller, o.energyOffered);
    }

    // Revoke a demand
    function revokeDemand (uint256 _idDemand, address _addr) public {
        Demand memory d = demands[_idDemand];
        require(d.addrBuyer == _addr, "Address provided doesn't match the address of the user who placed the demand");
        require(msg.sender == d.addrBuyer || msg.sender == owner, "Demand can be revoked only by the user who placed it or by the owner of the contract");
        delete demands[_idDemand];
        for(uint i=_idDemand;i<numberOfDemands-1;i++){
            demands[i]=demands[i+1];
        }
        demands[numberOfDemands-1]=Demand(0,address(0),"",0);
        numberOfDemands--;
        emit DemandRevoked(_idDemand, d.addrBuyer, d.nameBuyer, d.energyDemanded);
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

    // Make a deal
    function makeDeal(uint256 _idOffer, uint256 _idDemand) public {
        address addrSeller = offers[_idOffer].addrSeller;
        string memory nameSeller = offers[_idOffer].nameSeller;
        uint256 energyOffered = offers[_idOffer].energyOffered;
        address addrBuyer = demands[_idDemand].addrBuyer;
        string memory nameBuyer = demands[_idDemand].nameBuyer;
        uint256 energyDemanded = demands[_idDemand].energyDemanded;
        require(msg.sender == addrSeller || msg.sender == addrBuyer, "Deal can be made only by the buyer or the seller");
        require(energyOffered == energyDemanded, "Energy offered must be equal to energy demanded");
        uint256 NRGprice = energyOffered;
        require(tokenContract.balanceOf(addrBuyer) >= NRGprice * (10**18), "Buyer doesn't have enough NRG tokens");
        tokenContract.transferFrom(addrBuyer, addrSeller, NRGprice);
        delete offers[_idOffer];
        for(uint i=_idOffer;i<numberOfOffers-1;i++){
            offers[i]=offers[i+1];
        }
        offers[numberOfOffers-1]=Offer(0,address(0),"",0);
        numberOfOffers--;
        delete demands[_idDemand];
        for(uint i=_idDemand;i<numberOfDemands-1;i++){
            demands[i]=demands[i+1];
        }
        demands[numberOfDemands-1]=Demand(0,address(0),"",0);
        numberOfDemands--;
        emit DealMade(_idOffer, _idDemand, addrSeller, nameSeller, energyOffered, addrBuyer, nameBuyer, energyDemanded, NRGprice);
    }
}