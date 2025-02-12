// SPDX-License-Identifier: ISC
pragma solidity ^0.8.28;

import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { AgoraAccessControl } from "agora-contracts/access-control/AgoraAccessControl.sol";

contract AgoraWhitelist is AgoraAccessControl, Initializable, Ownable2StepUpgradeable {
    string public constant WHITELISTER_ROLE = "WHITELISTER_ROLE";

    string public constant APPROVED_ADDRESS_ROLE = "APPROVED_ADDRESS_ROLE";

    function initialize(address _initialAdminAddress, address _initialWhitelister) internal initializer {
        _initializeAgoraAccessControl({ _initialAdminAddress: _initialAdminAddress });
        AgoraAccessControl._addRoleToSet({ _role: WHITELISTER_ROLE });
        AgoraAccessControl._assignRole({ _role: WHITELISTER_ROLE, _newAddress: _initialWhitelister, _addRole: true });
        AgoraAccessControl._addRoleToSet({ _role: APPROVED_ADDRESS_ROLE });
    }

    function addToWhitelist(address _address) external {
        _requireSenderIsRole({ _role: WHITELISTER_ROLE });
        _assignRole({ _role: APPROVED_ADDRESS_ROLE, _newAddress: _address, _addRole: true });
        emit AddedToWhitelist({ _address: _address });
    }

    function removeFromWhitelist(address _address) external {
        _requireSenderIsRole({ _role: WHITELISTER_ROLE });
        _assignRole({ _role: APPROVED_ADDRESS_ROLE, _newAddress: _address, _addRole: false });
        emit RemovedFromWhitelist({ _address: _address });
    }

    function isApproved(address _address) external view returns (bool _isApproved) {
        _isApproved = _isRole({ _role: APPROVED_ADDRESS_ROLE, _address: _address });
    }

    struct Version {
        uint256 major;
        uint256 minor;
        uint256 patch;
    }

    function version() external pure returns (Version memory _version) {
        return Version({ major: 0, minor: 1, patch: 0 });
    }

    event AddedToWhitelist(address indexed _address);
    event RemovedFromWhitelist(address indexed _address);
}
