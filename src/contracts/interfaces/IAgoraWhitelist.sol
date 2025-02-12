// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IAgoraWhitelist {
    struct Version {
        uint256 major;
        uint256 minor;
        uint256 patch;
    }

    error AddressIsNotRole(string role);
    error InvalidInitialization();
    error NotInitializing();
    error OwnableInvalidOwner(address owner);
    error OwnableUnauthorizedAccount(address account);
    error RoleNameTooLong();

    event AddedToWhitelist(address indexed _address);
    event Initialized(uint64 version);
    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RemovedFromWhitelist(address indexed _address);
    event RoleAssigned(string indexed role, address indexed address_);
    event RoleRevoked(string indexed role, address indexed address_);

    function ACCESS_CONTROL_ADMIN_ROLE() external view returns (string memory);
    function AGORA_ACCESS_CONTROL_STORAGE_SLOT() external view returns (bytes32);
    function APPROVED_ADDRESS_ROLE() external view returns (string memory);
    function WHITELISTER_ROLE() external view returns (string memory);
    function acceptOwnership() external;
    function addToWhitelist(address _address) external;
    function assignRole(string memory _role, address _newAddress, bool _addRole) external;
    function getAllRoles() external view returns (string[] memory _roles);
    function getRoleMembers(string memory _role) external view returns (address[] memory _members);
    function hasRole(string memory _role, address _address) external view returns (bool);
    function isApproved(address _address) external view returns (bool _isApproved);
    function owner() external view returns (address);
    function pendingOwner() external view returns (address);
    function removeFromWhitelist(address _address) external;
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external;
    function version() external pure returns (Version memory _version);
}
