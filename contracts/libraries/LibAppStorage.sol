// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "./RivalIntervalTreeLibrary.sol";

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

bytes32 constant USER_ROLE = keccak256("USER_ROLE");
bytes32 constant APP_STORAGE_POSITION = keccak256("diamond.standard.app.storage");

  
struct LabOwner {
        string name;
        string email;
        string country;
    }

struct LabOwnerExt {
        address account;
        LabOwner base;
    }

struct LabUser {
        string email;
        uint256 startDate;
        uint256 endDate;
        address owner; // New field to store the account that added the LabUser
    }

struct LabUserExt {
        address account;
        LabUser base;
    }

struct Rental {
    address renter;
    uint256 tokenId;
    uint256 price;
    uint256 start;
    uint256 end;
}

struct Lab {
        string name;
        string url;
        uint256 price;
        uint startDate;
        uint endDate;
    }

struct LabExt {
        uint labId;
        address owner;
        Lab base;
}


struct AppStorage {

         bytes32 DEFAULT_ADMIN_ROLE;

         mapping(bytes32 role => EnumerableSet.AddressSet) _roleMembers;
        
         mapping(address => LabOwner) LabOwners;
         mapping(address => LabUser) LabUsers;
         mapping(address => RivalIntervalTreeLibrary.Tree) userCalendars;

         mapping(uint256 => RivalIntervalTreeLibrary.Tree) calendars;
         mapping(uint256 => mapping(uint256 => Rental)) rentals;

         mapping(uint => Lab)  Labs;
}

library LibAppStorage {
   // using RivalIntervalTreeLibrary for RivalIntervalTreeLibrary.Tree;
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        bytes32 position = APP_STORAGE_POSITION;
        assembly {
            ds.slot := position
            }
    }
}