// SPDX-License-Identifier: ISC
pragma solidity ^0.8.28;

import { BaseScript } from "../BaseScript.sol";
import { AgoraStableSwapPairCore, InitializeParams as AgoraStableSwapPairParams } from "@contracts/agora-stable-swap-pair/AgoraStableSwapPairCore.sol";

import { AgoraStableSwapRegistry } from "@contracts/agora-stable-swap-registry/AgoraStableSwapRegistry.sol";
import { AgoraProxyAdmin } from "@contracts/proxy/AgoraProxyAdmin.sol";
import { AgoraTransparentUpgradeableProxy, ConstructorParams as AgoraTransparentUpgradeableProxyParams } from "@contracts/proxy/AgoraTransparentUpgradeableProxy.sol";

struct DeployAgoraStableSwapPairReturn {
    address agoraStableSwapPairImplementation;
    address agoraStableSwapPair;
}

function deployAgoraStableSwapPair(
    address _proxyAdminAddress,
    AgoraStableSwapPairParams memory _agoraStableSwapPairParams
) returns (DeployAgoraStableSwapPairReturn memory) {
    AgoraStableSwapPairCore _pair = new AgoraStableSwapPairCore();
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

struct DeployAgoraStableSwapRegistryReturn {
    address agoraStableSwapRegistryImplementation;
    address agoraStableSwapRegistry;
}

function deployAgoraStableSwapRegistry(
    address _proxyAdminAddress,
    address _initialAdminAddress
) returns (DeployAgoraStableSwapRegistryReturn memory) {
    AgoraStableSwapRegistry _registry = new AgoraStableSwapRegistry();
    AgoraTransparentUpgradeableProxy _registryProxy = new AgoraTransparentUpgradeableProxy(
        AgoraTransparentUpgradeableProxyParams({
            logic: address(_registry),
            proxyAdminAddress: _proxyAdminAddress,
            data: abi.encodeWithSelector(AgoraStableSwapRegistry.initialize.selector, _initialAdminAddress)
        })
    );
    return
        DeployAgoraStableSwapRegistryReturn({
            agoraStableSwapRegistryImplementation: address(_registry),
            agoraStableSwapRegistry: address(_registryProxy)
        });
}
