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

import { AgoraAccessControl } from "../abstracts/AgoraAccessControl.sol";

contract AgoraStableSwapAccessControl is AgoraAccessControl {
    /// @notice the WHITELISTER_ROLE identifier
    string public constant WHITELISTER_ROLE = "WHITELISTER_ROLE";

    /// @notice the FEE_SETTER_ROLE identifier
    string public constant FEE_SETTER_ROLE = "FEE_SETTER_ROLE";

    /// @notice the TOKEN_REMOVER_ROLE identifier
    string public constant TOKEN_REMOVER_ROLE = "TOKEN_REMOVER_ROLE";

    /// @notice the PAUSER_ROLE identifier
    string public constant PAUSER_ROLE = "PAUSER_ROLE";

    /// @notice the APPROVED_SWAPPER identifier
    string public constant APPROVED_SWAPPER = "APPROVED_SWAPPER";

    /// @notice the PRICE_SETTER_ROLE identifier
    string public constant PRICE_SETTER_ROLE = "PRICE_SETTER_ROLE";

    function _initializeAgoraStableSwapAccessControl(address _initialAdminAddress) internal {
        _initializeAgoraAccessControl(_initialAdminAddress);
        // Set the default roles
        AgoraAccessControl._addRoleToSet(WHITELISTER_ROLE);
        AgoraAccessControl._addRoleToSet(FEE_SETTER_ROLE);
        AgoraAccessControl._addRoleToSet(TOKEN_REMOVER_ROLE);
        AgoraAccessControl._addRoleToSet(PAUSER_ROLE);
        AgoraAccessControl._addRoleToSet(APPROVED_SWAPPER);
        AgoraAccessControl._addRoleToSet(PRICE_SETTER_ROLE);
    }
}
