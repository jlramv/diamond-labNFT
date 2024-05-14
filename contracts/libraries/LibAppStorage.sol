// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "./RivalIntervalTreeLibrary.sol";

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

bytes32 constant USER_ROLE = keccak256("USER_ROLE");
bytes32 constant APP_STORAGE_POSITION = keccak256("diamond.standard.app.storage");

  
struct CPSOwner {
        string name;
        string email;
        string country;
    }

struct CPSOwnerExt {
        address account;
        CPSOwner base;
    }

struct CPSUser {
        string email;
        uint256 startDate;
        uint256 endDate;
        address owner; // New field to store the account that added the CPSUser
    }

struct CPSUserExt {
        address account;
        CPSUser base;
    }

struct Rental {
    address renter;
    uint256 tokenId;
    uint256 price;
    uint256 start;
    uint256 end;
}

struct CPS {
        string name;
        string url;
        uint256 price;
        uint startDate;
        uint endDate;
    }

struct CPSExt {
        uint CPSId;
        address owner;
        CPS base;
}


struct AppStorage {

         bytes32 DEFAULT_ADMIN_ROLE;

         mapping(bytes32 role => EnumerableSet.AddressSet) _roleMembers;
        
         mapping(address => CPSOwner) CPSOwners;
         mapping(address => CPSUser) CPSUsers;
         mapping(address => RivalIntervalTreeLibrary.Tree) userCalendars;

         mapping(uint256 => RivalIntervalTreeLibrary.Tree) calendars;
         mapping(uint256 => mapping(uint256 => Rental)) rentals;

         mapping(uint => CPS)  CPSs;
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