// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


contract owned{
    constructor() { owner = msg.sender;}
    address owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract EnergyStore {

    event OfferMade(address indexed producer, uint32 indexed day, uint32 indexed price, uint64 energy);
    event OfferRevoked(address indexed producer, uint32 indexed day, uint32 indexed price, uint64 energy);
    event Deal(address indexed producer, uint32 indexed day, uint32 price, uint64 energy, uint32 indexed userID);
    event DealRevoked(address indexed producer, uint32 indexed day, uint32 price, uint64 energy, uint32 indexed userID);

    uint64 constant mWh = 1;
    uint64 constant Wh = 1000* mWh;
    uint64 constant KWh = 1000* Wh;
    uint64 constant MWh = 1000* KWh;
    uint64 constant GWh = 1000* MWh;
    uint64 constant TWh = 1000* GWh;
    uint64 constant maxEnergy = 18446* GWh;
    uint64 constant nrgToken = KWh;

    struct Offer{

        address producer;
        uint32 day;
        uint32 price;
        uint64 energy;
        uint64 timestamp;
    }

    struct Demand {

        address producer;
        uint32 day;
        uint32 price;
        uint64 energy;
        uint32 userID;
        uint64 timestamp;
    }

    // Offers (for energy: offering energy for sale)
    Offer[] public Offers;
    // Demands (for energy: demanding energy to buy)
    Demand[] public Demands;

    //map ( address, day) to index into Offers
    mapping(address => mapping(uint32 => uint)) public OffersIndex;

    // map (userID ) to index into Demands(last take written)
    mapping(uint32 => uint) public DemandsIndex;
    
    function offer_energy(uint32 aday, uint32 aprice, uint64 aenergy, uint64 atimestamp) external {
        //require a minimum offer of 1 kWh
        //require(aenergy >= kWh);

        uint idx = OffersIndex[msg.sender][aday];

        // idx is either 0 or such that Offers[idx] has the right producer and day (or both 0 and ...)
        if((Offers.length > idx) && (Offers[idx].producer == msg.sender) && (Offers[idx].day == aday))
        {
            require(atimestamp > Offers[idx].timestamp);

            emit OfferRevoked(Offers[idx].producer, Offers[idx].day, Offers[idx].price,Offers[idx].energy);
        }

        //create entry with new index idx for (msg.sender,aday)
        idx = Offers.length;
        OffersIndex[msg.sender][aday]= idx;
        Offers.push(Offer({
            producer: msg.sender,
            day: aday,
            price: aprice,
            energy: aenergy,
            timestamp: atimestamp
        }));
        emit OfferMade(Offers[idx].producer, Offers[idx].day, Offers[idx].price, Offers[idx].energy);
    }

    function getOffersCount() external view returns(uint count) {
        return Offers.length;
    }

    function getOfferByProducerAndDay(address producer, uint32 day) external view returns(uint32 price, uint64 energy){
        uint idx = OffersIndex[producer][day];
        require(Offers[idx].producer == producer);
        require(Offers[idx].day == day);
        return(Offers[idx].price, Offers[idx].energy);
    }

    function buy_energy(address aproducer, uint32 aday, uint32 aprice, uint64 aenergy, uint32 auserID, uint64 atimestamp) external {
        buy_energy_core(aproducer, aday, aprice, aenergy, auserID, atimestamp);
    }

    function buy_energy_core(address aproducer, uint32 aday, uint32 aprice, uint64 aenergy, uint32 auserID, uint64 atimestamp) internal {
        uint idx = OffersIndex[aproducer][aday];

        if((Offers.length > idx) && (Offers[idx].producer == aproducer) && (Offers[idx].day == aday)) {
            require(Offers[idx].price == aprice);

            DemandsIndex[auserID] = Demands.length;
            Demands.push(Demand({
                producer: aproducer,
                day: aday,
                price: aprice,
                energy: aenergy,
                userID: auserID,
                timestamp: atimestamp
            }));
            emit Deal(aproducer, aday, aprice, aenergy, auserID); 
        }   else {
            revert();
        }     
    }

    function getDemandsCount() external view returns(uint count){
        return Demands.length;
    }

    function getsDemandByUserID(uint32 userID) external view returns(address producer, uint32 day, uint32 price, uint64 energy) {
        uint idx = DemandsIndex[userID];
        require(Demands[idx].userID == userID);
        return (Demands[idx].producer, Demands[idx].day, Demands[idx].price, Demands[idx].energy);
    }
}