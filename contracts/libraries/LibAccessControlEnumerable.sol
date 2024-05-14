// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/extensions/AccessControlEnumerable.sol)

pragma solidity ^0.8.20;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {LibAppStorage, AppStorage, USER_ROLE, CPSOwner, CPSUser, CPSOwnerExt, CPSUserExt} from "./LibAppStorage.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
library LibAccessControlEnumerable {
    using EnumerableSet for EnumerableSet.AddressSet;

    event UserAdded(address indexed account, string email, uint256 startDate, uint256 endDate);

    function _isCPSOwner(address account) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s._roleMembers[s.DEFAULT_ADMIN_ROLE].contains(account);
    }

    function _isCPSUser(address account) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s._roleMembers[USER_ROLE].contains(account);
    }

    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s._roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s._roleMembers[role].length();
    }

    /**
     * @dev Overload {AccessControl-_grantRole} to track enumerable memberships
     */
    function _addOwnerRole(address account, string memory name, string memory email, string memory country) internal returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s._roleMembers[s.DEFAULT_ADMIN_ROLE].add(account);
        s.CPSOwners[account] = CPSOwner(name, email, country);
        return true;
    }

    /**
     * @dev Overload {AccessControl-_revokeRole} to track enumerable memberships
     */
    function _removeOwnerRole(address account) internal returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s._roleMembers[s.DEFAULT_ADMIN_ROLE].remove(account);
        delete s.CPSOwners[account];
        return true;
    }

    function _addUserRole(address account, string memory email, uint256 startDate, uint256 endDate) internal returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s._roleMembers[USER_ROLE].add(account);
        s.CPSUsers[account] = CPSUser(email, startDate, endDate, account);
        emit UserAdded(account, email, startDate, endDate);
        return true;
    }

    function _removeUserRole(address account) internal returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s._roleMembers[USER_ROLE].remove(account);
        delete s.CPSUsers[account];
        return true;
    }

    function _getCPSOwners() internal view returns (CPSOwnerExt[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 totalCPSOwners = getRoleMemberCount(s.DEFAULT_ADMIN_ROLE);
        CPSOwnerExt[] memory CPSOwners = new CPSOwnerExt[](totalCPSOwners);
        for (uint256 i; i < totalCPSOwners; i++) {
            address account = getRoleMember(s.DEFAULT_ADMIN_ROLE, i);
            CPSOwners[i] = CPSOwnerExt(account, s.CPSOwners[account]);
        }
        return CPSOwners;
    }

    function _getCPSUsers() internal view returns (CPSUserExt[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 totalCPSUsers = getRoleMemberCount(USER_ROLE);
        CPSUserExt[] memory CPSUsers = new CPSUserExt[](totalCPSUsers);
        for (uint256 i; i < totalCPSUsers; i++) {
            address account = getRoleMember(USER_ROLE, i);
            CPSUsers[i] = CPSUserExt(account, s.CPSUsers[account]);
        }
        return CPSUsers;
    }
}
