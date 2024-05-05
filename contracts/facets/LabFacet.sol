// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import  "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "../libraries/RivalIntervalTreeLibrary.sol";
import {LibAppStorage, AppStorage, Lab, LabExt, Rental} from "../libraries/LibAppStorage.sol";
import {LibToken809} from "../libraries/LibToken809.sol";
import {LibAccessControlEnumerable} from "../libraries/LibAccessControlEnumerable.sol";


contract LabFacet is ERC721EnumerableUpgradeable{
    using RivalIntervalTreeLibrary for RivalIntervalTreeLibrary.Tree;

    uint private _labId;
    constructor() {}

    modifier isLabOwner() {
        require(
            LibAccessControlEnumerable._isLabOwner(msg.sender),
            "Only the LabOwner can perform this action"
        );
        _;
    }

    modifier isLabUser() {
        require(
            LibAccessControlEnumerable._isLabUser(msg.sender),
            "Only one LabUsers can perform this action"
        );
        _;
    }

    modifier isOwner(uint labId) {
        require(ownerOf(labId) == msg.sender, "Only the owner");
        _;
    }

    function initialize(string memory _name, string memory _symbol )  initializer public{
        __ERC721_init(_name, _symbol);
        _labId=0;
    }

    function addLab(
        string memory name,
        string memory url,
        uint256 price,
        uint startDate,
        uint endDate
    ) external isLabOwner returns (bool success){
        AppStorage storage s = LibAppStorage.diamondStorage();
        _labId++;
        _safeMint(msg.sender, _labId);
        s.Labs[_labId] = Lab(name, url, price, startDate, endDate);
        return true;
    }

    function updateLab(
        uint labId,
        string memory name,
        string memory url,
        uint256 price,
        uint startDate,
        uint endDate
    ) external isLabOwner isOwner(labId) returns (bool success){
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.Labs[labId].startDate != 0, "Lab does not exist");

        s.Labs[labId] = Lab(name, url, price, startDate, endDate);
        return true;
    }

    function deleteLab(uint labId) external isLabOwner isOwner(labId) returns (bool success){
        AppStorage storage s = LibAppStorage.diamondStorage();
        
        require(s.Labs[labId].startDate != 0, "Lab does not exist");
        _burn(labId);
        delete s.Labs[labId];
        return true;
    }

    function getLab(uint labId) public view returns (Lab memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        
        return s.Labs[labId];
    }

     function transferLab(uint labId, address to) external isOwner(labId) returns (bool success){
         AppStorage storage s = LibAppStorage.diamondStorage();
        
        require(s.Labs[labId].startDate != 0, "Lab does not exist");
        require(
            LibAccessControlEnumerable._isLabOwner(to),
            "Only one lab owner can receive Lab"
        );
        _transfer(msg.sender, to, labId);
        return true;
    }

    function getAllLabs() public view returns (LabExt[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint totalSupply = totalSupply();
        LabExt[] memory labs = new LabExt[](totalSupply);
        uint labId;

        for (uint256 i = 0; i < totalSupply; i++) {
            labId = tokenByIndex(i);
            labs[i] = LabExt(labId, ownerOf(labId), s.Labs[labId]);
        }
        return labs;
    }

     function bookLab(
        uint256 labId,
        uint256 _start,
        uint256 _end
    ) external payable isLabUser returns (bool success) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_start < _end, "Invalid range");

        Lab memory lab = s.Labs[labId];
        require(lab.startDate != 0, "Lab does not exist");
        require(
            _start >= lab.startDate && _end <= lab.endDate,
            "Interval out of range"
        );
        require(msg.value >= lab.price, "Insufficient funds");
        s.userCalendars[msg.sender].insert(_start, _end);
        
        if (LibToken809.reserve(msg.sender, labId, _start, _end, lab.price)) {
            address payable owner = payable(ownerOf(labId));
            owner.transfer(lab.price);
            return true;
        }
        return false;
    }

    function cancelBookLab(
        uint256 labId,
        uint256 _start
    ) external returns (bool success) {
        require(
            ownerOf(labId) == msg.sender ||
                LibToken809.renterOf(labId, _start) == msg.sender,
            "Only the owner"
        );
        LibToken809.cancelReservation(labId, _start);
        return true;
    }

    function getAllBookings() external view returns (Rental[] memory) {
        LabExt[] memory labs = getAllLabs();

        uint totalBookings = 0;

        for (uint256 i = 0; i < labs.length; i++) {
            totalBookings += LibToken809.getRentalCount(labs[i].labId);
        }

        Rental[] memory _bookings = new Rental[](totalBookings);

        uint256 k = 0;
        for (uint256 i = 0; i < labs.length; i++) {
            Rental[] memory _rentalAux = LibToken809.getAllRentals(
                labs[i].labId
            );

            for (uint256 j = 0; j < _rentalAux.length; j++) {
                _bookings[k] = _rentalAux[j];
                k++;
            }
        }

        return _bookings;
    }

    function getBooking(uint labId, uint256 _start)
        external
        view
        returns (Rental memory)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint cursor = s.calendars[labId].findParent(_start);
        if (s.rentals[labId][cursor].renter == msg.sender) {
            return s.rentals[labId][cursor];
        }else 
            return Rental(address(0),0,0,0,0);
    }

    

   // function supportsInterface(bytes4 _interfaceID) external view override returns (bool) {}
}