// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import { AgoraAccessControl } from "./abstracts/AgoraAccessControl.sol";

contract AgoraStableSwapRegistryAccessControl is AgoraAccessControl {
    /// @notice the WHITELISTER_ROLE identifier
    string public constant WHITELISTER_ROLE = "WHITELISTER_ROLE";

    /// @notice the BOOKKEEPER_ROLE identifier
    string public constant BOOKKEEPER_ROLE = "BOOKKEEPER_ROLE";

    /// @notice the PAUSER_ROLE identifier
    string public constant PAUSER_ROLE = "PAUSER_ROLE";

    function _initializeAgoraStableSwapRegistryAccessControl(address _initialAdminAddress) internal {
        _initializeAgoraAccessControl(_initialAdminAddress);

        // Set the default roles
        AgoraAccessControl._addRoleToSet(WHITELISTER_ROLE);
        AgoraAccessControl._addRoleToSet(BOOKKEEPER_ROLE);
        AgoraAccessControl._addRoleToSet(PAUSER_ROLE);
    }
}
