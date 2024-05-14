// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

// Uncomment this line to use console.log
//import "hardhat/console.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {LibAppStorage, AppStorage, USER_ROLE, CPSOwnerExt, CPSUserExt, CPSUser, CPSOwner} from "../libraries/LibAppStorage.sol";
import {LibAccessControlEnumerable} from "../libraries/LibAccessControlEnumerable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";


contract CPSAccessControlFacet is AccessControlUpgradeable {
 
   using EnumerableSet for EnumerableSet.AddressSet;

    constructor() {}

    modifier onlyCPSUserOwner(address account) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(
            s.CPSUsers[account].owner == msg.sender,
            "Only the account that added the CPSUser can perform this action"
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
 
    /**
     * @dev Adds a new owner with the specified name, account address, email, and country.
     * Only the contract owner can call this function.
     * The account must not already have the USER_ROLE.
     * Returns true if the owner is successfully added, false otherwise.
     * 
     * @param name The name of the new owner.
     * @param account The account address of the new owner.
     * @param email The email of the new owner.
     * @param country The country of the new owner.
     * 
     * @return success A boolean indicating whether the owner was successfully added.
     */
    function addOwner(
        string memory name,
        address account,
        string memory email,
        string memory country
    ) external notOwner(account) returns (bool success) {
        require(!hasRole(USER_ROLE, account), "Account already has USER_ROLE"); 
        bool granted = _grantRole(DEFAULT_ADMIN_ROLE, account);
        if (granted) 
            LibAccessControlEnumerable._addOwnerRole(account, name, email, country);
        return granted;
    }

    /**
     * @dev Removes the owner role from the caller.
     * Only the default admin role can call this function.
     * This function revokes the DEFAULT_ADMIN_ROLE from the caller and removes their owner role.
     * @return success A boolean indicating whether the operation was successful or not.
     */
    function removeOwner() external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool success){
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        LibAccessControlEnumerable._removeOwnerRole(msg.sender);    
        return true;

        // TODO: What if the owner has CPSUsers and/or CPSs?
    }

    /**
     * @dev Updates the owner information for the caller.
     * @param name The name of the owner.
     * @param email The email address of the owner.
     * @param country The country of the owner.
     * @return success A boolean indicating whether the update was successful.
     */
    function updateOwner(
        string memory name,
        string memory email,
        string memory country
    ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool success){
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.CPSOwners[msg.sender] = CPSOwner(name, email, country);
        return true;
    }

    function isCPSOwner(address account) external view returns (bool) {
        return LibAccessControlEnumerable._isCPSOwner(account);
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
    ) external onlyRole(DEFAULT_ADMIN_ROLE) onlyCPSUserOwner(account) returns (bool success){
        
        revokeRole(USER_ROLE, account);
        LibAccessControlEnumerable._removeUserRole(account);
        return true;
    }

    function updateAllowed(
        address account,
        string memory email,
        uint256 startDate,
        uint256 endDate
    ) external onlyCPSUserOwner(account) onlyRole(DEFAULT_ADMIN_ROLE) returns (bool success){
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.CPSUsers[account] = CPSUser(email, startDate, endDate, msg.sender);
        return true;
    }

    function isCPSUser(address account) external view returns (bool) {
        return LibAccessControlEnumerable._isCPSUser(account);
    }

    function getCPSOwners() external view returns (CPSOwnerExt[] memory) {
        return LibAccessControlEnumerable._getCPSOwners();
    }

    function getCPSUsers() external view returns (CPSUserExt[] memory) {
        return LibAccessControlEnumerable._getCPSUsers();
    }

    function getCPSUser(
        address account
    ) external view returns (CPSUser memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.CPSUsers[account];
    }
    
}
