// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "./RivalIntervalTreeLibrary.sol";
import {LibAppStorage, USER_ROLE, AppStorage, Rental} from "./LibAppStorage.sol";

library LibToken809 {
     using RivalIntervalTreeLibrary for RivalIntervalTreeLibrary.Tree;

    event Reserved(
        address renter,
        uint256 tokenId,
        uint256 start,
        uint256 end);

    event Canceled(
        address renter,
        uint256 tokenId,
        uint256 start,
        uint256 end);

    function getRentalCount(uint256 _tokenId) public view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.calendars[_tokenId].size();
    }

    function getRentalKeys(
        uint256 _tokenId
    ) public view returns (uint256[] memory) {
         AppStorage storage s = LibAppStorage.diamondStorage();
        return s.calendars[_tokenId].getAllKeys();
    }

    function getAllRentals(
        uint256 _tokenId
    ) public view returns (Rental[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 totalRentals = s.calendars[_tokenId].size();
        Rental[] memory _rentals = new Rental[](totalRentals);
        uint256 k = 0;
        uint256[] memory keys = s.calendars[_tokenId].getAllKeys();

        for (uint256 j = 0; j < keys.length; j++) {
            _rentals[k] = s.rentals[_tokenId][keys[j]];
            k++;
        }
        return _rentals;
    }

    function renterOf(
        uint256 _tokenId,
        uint256 _time
    ) public view returns (address) {
        // TODO - look for bounding interval
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.rentals[_tokenId][_time].renter;
    }

    function checkAvailable(
        uint256 _tokenId,
        uint256 _start,
        uint256 _end
    ) public view returns (bool available) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return !s.calendars[_tokenId].overlaps(_start, _end);
    }

    function reserve(
        address _renter,
        uint256 _tokenId,
        uint256 _start,
        uint256 _end,
        uint256 _price
    ) public  returns (bool success) {
        // Reverts if impossible
        /*   require(
            !renterCalendars[msg.sender].overlaps(_start, _end),
            "User already reserved one CPS"
        );*/
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(!s.userCalendars[_renter].overlaps(_start, _end), "User already reserved one CPS");
        s.calendars[_tokenId].insert(_start, _end);
        //      renterCalendars[msg.sender].insert(_start, _end);
        Rental memory rental = Rental(_renter, _tokenId, _price, _start, _end);
        s.rentals[_tokenId][_start] = rental;
        emit Reserved(_renter, _tokenId, _start, _end);
        return true;
    }

    function cancelReservation(
        uint256 _tokenId,
        uint256 _start
    ) external  returns (bool success) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.calendars[_tokenId].remove(_start);
        s.userCalendars[s.rentals[_tokenId][_start].renter].remove(_start);
        delete s.rentals[_tokenId][_start];
        emit Canceled(
            s.rentals[_tokenId][_start].renter,
            _tokenId,
            _start,
            _start
        );
        return true;
    }

}