// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import  "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "../libraries/RivalIntervalTreeLibrary.sol";
import {LibAppStorage, AppStorage, CPS, CPSExt, Rental} from "../libraries/LibAppStorage.sol";
import {LibToken809} from "../libraries/LibToken809.sol";
import {LibAccessControlEnumerable} from "../libraries/LibAccessControlEnumerable.sol";
import "../external/CPSERC20.sol";

contract CPSFacet is ERC721EnumerableUpgradeable{
    using RivalIntervalTreeLibrary for RivalIntervalTreeLibrary.Tree;
    CPSERC20 public cPSERC20;

    uint private _CPSId;
    constructor() {}

    modifier isCPSOwner() {
        require(
            LibAccessControlEnumerable._isCPSOwner(msg.sender),
            "Only the CPSOwner can perform this action"
        );
        _;
    }

    modifier isCPSUser() {
        require(
            LibAccessControlEnumerable._isCPSUser(msg.sender),
            "Only one CPSUsers can perform this action"
        );
        _;
    }

    modifier isOwner(uint CPSId) {
        require(ownerOf(CPSId) == msg.sender, "Only the owner");
        _;
    }

    function initialize(string memory _name, string memory _symbol, address _CPSERC20 )  initializer public{
        __ERC721_init(_name, _symbol);
        cPSERC20 = CPSERC20(_CPSERC20);
        _CPSId=0;
    }

    function addCPS(
        string memory name,
        string memory url,
        uint256 price,
        uint startDate,
        uint endDate
    ) external isCPSOwner returns (bool success){
        AppStorage storage s = LibAppStorage.diamondStorage();
        _CPSId++;
        _safeMint(msg.sender, _CPSId);
        s.CPSs[_CPSId] = CPS(name, url, price, startDate, endDate);
        return true;
    }

    function updateCPS(
        uint CPSId,
        string memory name,
        string memory url,
        uint256 price,
        uint startDate,
        uint endDate
    ) external isCPSOwner isOwner(CPSId) returns (bool success){
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.CPSs[CPSId].startDate != 0, "CPS does not exist");

        s.CPSs[CPSId] = CPS(name, url, price, startDate, endDate);
        return true;
    }

    function deleteCPS(uint CPSId) external isCPSOwner isOwner(CPSId) returns (bool success){
        AppStorage storage s = LibAppStorage.diamondStorage();
        
        require(s.CPSs[CPSId].startDate != 0, "CPS does not exist");
        _burn(CPSId);
        delete s.CPSs[CPSId];
        return true;
    }

    function getCPS(uint CPSId) public view returns (CPS memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        
        return s.CPSs[CPSId];
    }

     function transferCPS(uint CPSId, address to) external isOwner(CPSId) returns (bool success){
         AppStorage storage s = LibAppStorage.diamondStorage();
        
        require(s.CPSs[CPSId].startDate != 0, "CPS does not exist");
        require(
            LibAccessControlEnumerable._isCPSOwner(to),
            "Only one CPS owner can receive CPS"
        );
        _transfer(msg.sender, to, CPSId);
        return true;
    }

    function getAllCPSs() public view returns (CPSExt[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint totalSupply = totalSupply();
        CPSExt[] memory CPSs = new CPSExt[](totalSupply);
        uint CPSId;

        for (uint256 i = 0; i < totalSupply; i++) {
            CPSId = tokenByIndex(i);
            CPSs[i] = CPSExt(CPSId, ownerOf(CPSId), s.CPSs[CPSId]);
        }
        return CPSs;
    }

     function bookCPS(
        uint256 CPSId,
        uint256 _start,
        uint256 _end
    ) external payable isCPSUser returns (bool success) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_start < _end, "Invalid range");

        CPS memory cps = s.CPSs[CPSId];
        require(cps.startDate != 0, "CPS does not exist");
        require(
            _start >= cps.startDate && _end <= cps.endDate,
            "Interval out of range"
        );
        require(msg.value >= cps.price, "Insufficient funds");
        s.userCalendars[msg.sender].insert(_start, _end);
        
        if (LibToken809.reserve(msg.sender, CPSId, _start, _end, cps.price)) {
            address payable owner = payable(ownerOf(CPSId));
            owner.transfer(cps.price);
            return true;
        }
        return false;
    }

    function cancelBookCPS(
        uint256 CPSId,
        uint256 _start
    ) external returns (bool success) {
        require(
            ownerOf(CPSId) == msg.sender ||
                LibToken809.renterOf(CPSId, _start) == msg.sender,
            "Only the owner"
        );
        LibToken809.cancelReservation(CPSId, _start);
        return true;
    }

    function getAllBookings() external view returns (Rental[] memory) {
        CPSExt[] memory CPSs = getAllCPSs();

        uint totalBookings = 0;

        for (uint256 i = 0; i < CPSs.length; i++) {
            totalBookings += LibToken809.getRentalCount(CPSs[i].CPSId);
        }

        Rental[] memory _bookings = new Rental[](totalBookings);

        uint256 k = 0;
        for (uint256 i = 0; i < CPSs.length; i++) {
            Rental[] memory _rentalAux = LibToken809.getAllRentals(
                CPSs[i].CPSId
            );

            for (uint256 j = 0; j < _rentalAux.length; j++) {
                _bookings[k] = _rentalAux[j];
                k++;
            }
        }

        return _bookings;
    }

    function getBooking(uint CPSId, uint256 _start)
        external
        view
        returns (Rental memory)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint cursor = s.calendars[CPSId].findParent(_start);
        if (s.rentals[CPSId][cursor].renter == msg.sender) {
            return s.rentals[CPSId][cursor];
        }else 
            return Rental(address(0),0,0,0,0);
    }

   // function supportsInterface(bytes4 _interfaceID) external view override returns (bool) {}
}