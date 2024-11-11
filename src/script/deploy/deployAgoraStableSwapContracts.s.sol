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
// ================== deployAgoraStableSwapContracts ==================
// ====================================================================

import { AgoraStableSwapPair } from "contracts/AgoraStableSwapPair.sol";
import { AgoraStableSwapPairCore, InitializeParams as AgoraStableSwapPairParams } from "contracts/AgoraStableSwapPairCore.sol";

import { AgoraTransparentUpgradeableProxy, ConstructorParams as AgoraTransparentUpgradeableProxyParams } from "agora-contracts/proxy/AgoraTransparentUpgradeableProxy.sol";

/// @notice The ```DeployAgoraStableSwapPairReturn``` struct is used to return the address of the AgoraStableSwapPair implementation and the address of the AgoraStableSwapPair
/// @param agoraStableSwapPairImplementation The address of the AgoraStableSwapPair implementation
/// @param agoraStableSwapPair The address of the AgoraStableSwapPair
struct DeployAgoraStableSwapPairReturn {
    address agoraStableSwapPairImplementation;
    address agoraStableSwapPair;
}

/// @notice The ```deployAgoraStableSwapPair``` function is used to deploy the AgoraStableSwapPair contract
/// @param _proxyAdminAddress The address of the proxy admin
/// @param _agoraStableSwapPairParams The parameters for the AgoraStableSwapPair
/// @return The address of the AgoraStableSwapPair implementation and the address of the AgoraStableSwapPair
function deployAgoraStableSwapPair(
    address _proxyAdminAddress,
    AgoraStableSwapPairParams memory _agoraStableSwapPairParams
) returns (DeployAgoraStableSwapPairReturn memory) {
    AgoraStableSwapPair _pair = new AgoraStableSwapPair();
    AgoraTransparentUpgradeableProxy _pairProxy = new AgoraTransparentUpgradeableProxy(
        AgoraTransparentUpgradeableProxyParams({
            logic: address(_pair),
            proxyAdminAddress: _proxyAdminAddress,
            data: abi.encodeWithSelector(AgoraStableSwapPairCore.initialize.selector, _agoraStableSwapPairParams)
        })
    );
    return
        DeployAgoraStableSwapPairReturn({
            agoraStableSwapPairImplementation: address(_pair),
            agoraStableSwapPair: address(_pairProxy)
        });
}
