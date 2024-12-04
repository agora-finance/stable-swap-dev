// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

// ====================================================================
//             _        ______     ___   _______          _
//            / \     .' ___  |  .'   `.|_   __ \        / \
//           / _ \   / .'   \_| /  .-.  \ | |__) |      / _ \
//          / ___ \  | |   ____ | |   | | |  __ /      / ___ \
//        _/ /   \ \_\ `.___]  |\  `-'  /_| |  \ \_  _/ /   \ \_
//       |____| |____|`._____.'  `.___.'|____| |___||____| |____|
// ====================================================================
// ================== AgoraStableSwapAccessControl ====================
// ====================================================================

import { AgoraAccessControl } from "agora-contracts/access-control/AgoraAccessControl.sol";

/// @title AgoraStableSwapAccessControl
/// @notice The AgoraStableSwapAccessControl is a contract that manages the access control for the AgoraStableSwapPair
/// @author Agora
contract AgoraStableSwapAccessControl is AgoraAccessControl {
    /// @notice the WHITELISTER_ROLE identifier
    string public constant WHITELISTER_ROLE = "WHITELISTER_ROLE";

    /// @notice the FEE_SETTER_ROLE identifier
    string public constant FEE_SETTER_ROLE = "FEE_SETTER_ROLE";

    /// @notice the TOKEN_REMOVER_ROLE identifier
    string public constant TOKEN_REMOVER_ROLE = "TOKEN_REMOVER_ROLE";

    /// @notice the PAUSER_ROLE identifier
    string public constant PAUSER_ROLE = "PAUSER_ROLE";

    //! TODO: APPROVED_SWAPPER_ROLE?
    /// @notice the APPROVED_SWAPPER identifier
    string public constant APPROVED_SWAPPER = "APPROVED_SWAPPER";

    /// @notice the PRICE_SETTER_ROLE identifier
    string public constant PRICE_SETTER_ROLE = "PRICE_SETTER_ROLE";

    /// @notice The ```_initializeAgoraStableSwapAccessControl``` function initializes the AgoraStableSwapAccessControl contract
    /// @dev This function adds the default roles that are required by the AgoraStableSwapPair
    /// @param _initialAdminAddress The address of the initial admin
    function _initializeAgoraStableSwapAccessControl(address _initialAdminAddress) internal {
        _initializeAgoraAccessControl({ _initialAdminAddress: _initialAdminAddress });
        // Set the default roles
        AgoraAccessControl._addRoleToSet({ _role: WHITELISTER_ROLE });
        AgoraAccessControl._addRoleToSet({ _role: FEE_SETTER_ROLE });
        AgoraAccessControl._addRoleToSet({ _role: TOKEN_REMOVER_ROLE });
        AgoraAccessControl._addRoleToSet({ _role: PAUSER_ROLE });
        AgoraAccessControl._addRoleToSet({ _role: APPROVED_SWAPPER });
        AgoraAccessControl._addRoleToSet({ _role: PRICE_SETTER_ROLE });
    }
}
