// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import { AgoraAccessControl } from "./abstracts/AgoraAccessControl.sol";

contract AgoraStableSwapAccessControl is AgoraAccessControl {

    /// @notice the FEE_SETTER_ROLE identifier
    string public constant FEE_SETTER_ROLE = "FEE_SETTER_ROLE";

    /// @notice the SWAP_APPROVER_ROLE identifier
    string public constant SWAP_APPROVER_ROLE = "SWAP_APPROVER_ROLE";

    /// @notice the APPROVED_SWAPPER_ROLE identifier
    string public constant APPROVED_SWAPPER_ROLE = "APPROVED_SWAPPER_ROLE";

    function _initializeAgoraStableSwapAccessControl() internal {
        // Set the default roles
        AgoraAccessControl._addRoleToSet(FEE_SETTER_ROLE);
        AgoraAccessControl._addRoleToSet(SWAP_APPROVER_ROLE);
        AgoraAccessControl._addRoleToSet(APPROVED_SWAPPER_ROLE);
    }


}