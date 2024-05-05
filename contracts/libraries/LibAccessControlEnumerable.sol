// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/extensions/AccessControlEnumerable.sol)

pragma solidity ^0.8.20;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {LibAppStorage, AppStorage, USER_ROLE, LabOwner, LabUser, LabOwnerExt, LabUserExt} from "./LibAppStorage.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
library LibAccessControlEnumerable {
    using EnumerableSet for EnumerableSet.AddressSet;

    event UserAdded(address indexed account, string email, uint256 startDate, uint256 endDate);

    function _isLabOwner(address account) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s._roleMembers[s.DEFAULT_ADMIN_ROLE].contains(account);
    }

    function _isLabUser(address account) internal view returns (bool) {
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
        s.LabOwners[account] = LabOwner(name, email, country);
        return true;
    }

    /**
     * @dev Overload {AccessControl-_revokeRole} to track enumerable memberships
     */
    function _removeOwnerRole(address account) internal returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s._roleMembers[s.DEFAULT_ADMIN_ROLE].remove(account);
        delete s.LabOwners[account];
        return true;
    }

    function _addUserRole(address account, string memory email, uint256 startDate, uint256 endDate) internal returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s._roleMembers[USER_ROLE].add(account);
        s.LabUsers[account] = LabUser(email, startDate, endDate, account);
        emit UserAdded(account, email, startDate, endDate);
        return true;
    }

    function _removeUserRole(address account) internal returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s._roleMembers[USER_ROLE].remove(account);
        delete s.LabUsers[account];
        return true;
    }

    function _getLabOwners() internal view returns (LabOwnerExt[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 totalLabOwners = getRoleMemberCount(s.DEFAULT_ADMIN_ROLE);
        LabOwnerExt[] memory labOwners = new LabOwnerExt[](totalLabOwners);
        for (uint256 i; i < totalLabOwners; i++) {
            address account = getRoleMember(s.DEFAULT_ADMIN_ROLE, i);
            labOwners[i] = LabOwnerExt(account, s.LabOwners[account]);
        }
        return labOwners;
    }

    function _getLabUsers() internal view returns (LabUserExt[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 totalLabUsers = getRoleMemberCount(USER_ROLE);
        LabUserExt[] memory labUsers = new LabUserExt[](totalLabUsers);
        for (uint256 i; i < totalLabUsers; i++) {
            address account = getRoleMember(USER_ROLE, i);
            labUsers[i] = LabUserExt(account, s.LabUsers[account]);
        }
        return labUsers;
    }
}
