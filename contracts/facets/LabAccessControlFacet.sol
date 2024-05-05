// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

// Uncomment this line to use console.log
//import "hardhat/console.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {LibAppStorage, AppStorage, USER_ROLE, LabOwnerExt, LabUserExt, LabUser, LabOwner} from "../libraries/LibAppStorage.sol";
import {LibAccessControlEnumerable} from "../libraries/LibAccessControlEnumerable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";


contract LabAccessControlFacet is AccessControlUpgradeable {
 
   using EnumerableSet for EnumerableSet.AddressSet;

    constructor() {}

    modifier onlyLabUserOwner(address account) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(
            s.LabUsers[account].owner == msg.sender,
            "Only the account that added the LabUser can perform this action"
        );
        _;
    }

    modifier notOwner(address account) {
        require(
            !hasRole(DEFAULT_ADMIN_ROLE, account),
            "Account already has DEFAULT_ADMIN_ROLE"
        );
        _;
    }

    function initialize (
        string memory name,
        string memory email,
        string memory country
    ) public initializer {
        bool granted = _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        if (granted) 
            LibAccessControlEnumerable._addOwnerRole(msg.sender, name, email, country);

        AppStorage storage s = LibAppStorage.diamondStorage();
        s.DEFAULT_ADMIN_ROLE = DEFAULT_ADMIN_ROLE;    
            
    }
 
    function addOwner(
        string memory name,
        address account,
        string memory email,
        string memory country
    ) external notOwner(account)returns (bool success){
        require(!hasRole(USER_ROLE, account), "Account already has USER_ROLE"); 
        bool granted = _grantRole(DEFAULT_ADMIN_ROLE, account);
        if (granted) 
            LibAccessControlEnumerable._addOwnerRole(account, name, email, country);
        return granted;
    }

    function removeOwner() external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool success){
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        LibAccessControlEnumerable._removeOwnerRole(msg.sender);    
        return true;
    }

    function updateOwner(
        string memory name,
        string memory email,
        string memory country
    ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool success){
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.LabOwners[msg.sender] = LabOwner(name, email, country);
        return true;
    }

    function isLabOwner(address account) external view returns (bool) {
        return LibAccessControlEnumerable._isLabOwner(account);
    }

    function addAllowed(
        address account,
        string memory email,
        uint256 startDate,
        uint256 endDate
    ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool success){

        require(
            !hasRole(DEFAULT_ADMIN_ROLE, account),
            "Account already has DEFAULT_ADMIN_ROLE"
        );
        require(!hasRole(USER_ROLE, account), "Account already has USER_ROLE");
        if (_grantRole(USER_ROLE, account)){
            LibAccessControlEnumerable._addUserRole(account, email, startDate, endDate);
            return true;
        }else {
            return false;
        }
        
    }

    function removeAllowed(
        address account
    ) external onlyRole(DEFAULT_ADMIN_ROLE) onlyLabUserOwner(account) returns (bool success){
        
        revokeRole(USER_ROLE, account);
        LibAccessControlEnumerable._removeUserRole(account);
        return true;
    }

    function updateAllowed(
        address account,
        string memory email,
        uint256 startDate,
        uint256 endDate
    ) external onlyLabUserOwner(account) onlyRole(DEFAULT_ADMIN_ROLE) returns (bool success){
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.LabUsers[account] = LabUser(email, startDate, endDate, msg.sender);
        return true;
    }

    function isLabUser(address account) external view returns (bool) {
        return LibAccessControlEnumerable._isLabUser(account);
    }

    function getLabOwners() external view returns (LabOwnerExt[] memory) {
        return LibAccessControlEnumerable._getLabOwners();
    }

    function getLabUsers() external view returns (LabUserExt[] memory) {
        return LibAccessControlEnumerable._getLabUsers();
    }

    function getLabUser(
        address account
    ) external view returns (LabUser memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.LabUsers[account];
    }
    
}
