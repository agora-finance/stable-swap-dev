// SPDX-License-Identifier: ISC
pragma solidity ^0.8.28;

// ====================================================================
//             _        ______     ___   _______          _
//            / \     .' ___  |  .'   `.|_   __ \        / \
//           / _ \   / .'   \_| /  .-.  \ | |__) |      / _ \
//          / ___ \  | |   ____ | |   | | |  __ /      / ___ \
//        _/ /   \ \_\ `.___]  |\  `-'  /_| |  \ \_  _/ /   \ \_
//       |____| |____|`._____.'  `.___.'|____| |___||____| |____|
// ====================================================================
// =============== AgoraStableSwapRegistryAccessControl ===============
// ====================================================================

import { AgoraAccessControl } from "agora-contracts/access-control/AgoraAccessControl.sol";

/// @title AgoraStableSwapRegistryAccessControl
/// @notice The AgoraStableSwapRegistryAccessControl contract is used to manage the access control for the AgoraStableSwapRegistry contract
/// @author Agora
contract AgoraStableSwapRegistryAccessControl is AgoraAccessControl {
    /// @notice the WHITELISTER_ROLE identifier
    string public constant WHITELISTER_ROLE = "WHITELISTER_ROLE";

    /// @notice the BOOKKEEPER_ROLE identifier
    string public constant BOOKKEEPER_ROLE = "BOOKKEEPER_ROLE";

    /// @notice the PAUSER_ROLE identifier
    string public constant PAUSER_ROLE = "PAUSER_ROLE";

    /// @notice the ```_initializeAgoraStableSwapRegistryAccessControl``` function initializes the AgoraStableSwapRegistryAccessControl contract
    /// @param _initialAdminAddress the address of the initial admin
    function _initializeAgoraStableSwapRegistryAccessControl(address _initialAdminAddress) internal {
        _initializeAgoraAccessControl(_initialAdminAddress);

        // ! TODO: should this be called direclty since its inherited?
        // Set the default roles
        AgoraAccessControl._addRoleToSet(WHITELISTER_ROLE);
        AgoraAccessControl._addRoleToSet(BOOKKEEPER_ROLE);
        AgoraAccessControl._addRoleToSet(PAUSER_ROLE);
    }
}
