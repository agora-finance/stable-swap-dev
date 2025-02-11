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

import { AgoraStableSwapPair, InitializeParams as AgoraStableSwapPairParams } from "contracts/AgoraStableSwapPair.sol";
import { AgoraStableSwapPairCore } from "contracts/AgoraStableSwapPairCore.sol";

import { AgoraTransparentUpgradeableProxy, ConstructorParams as AgoraTransparentUpgradeableProxyParams } from "agora-contracts/proxy/AgoraTransparentUpgradeableProxy.sol";
import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";

contract Deploy is Script {
    address private constant AUSD_TOKEN = 0x6DE8be98b070722Da078216a8aEfDF615Bd69dC5; // testnet AUSD
    address private constant CONSTANT_TOKEN = 0xBF2F4BDfd8F9ed0e3193a5cc1a2CFaFe4B1290FB;
    address private constant INTEREST_BEARING_TOKEN = 0x06729D8f942E00d0ae9FD786c1E38dA4649D628F;

    address public constant HOTWALLET_DEPLOYER = 0x607199c8c50F413CE103bf3dbA33c94Ed067faF3;
    address public constant PROXY_ADMIN_OWNER = 0x99B0E95Fa8F5C3b86e4d78ED715B475cFCcf6E97;

    function run() public broadcaster returns (address _pairImplementationAddress) {
        // deploy the instance of the AgoraStableSwapPair implementation
        AgoraStableSwapPair _pair = new AgoraStableSwapPair();
        _pairImplementationAddress = address(_pair);
        console.log("Deployed AgoraStableSwapPair at:", _pairImplementationAddress);

        // deploy faucet implementation
        AgoraStableSwapPairParams memory _pairParams = AgoraStableSwapPairParams({
            token0: AUSD_TOKEN,
            token0Decimals: 6,
            token1: CONSTANT_TOKEN,
            token1Decimals: 18,
            minToken0PurchaseFee: 1e14,
            maxToken0PurchaseFee: 1e18,
            minToken1PurchaseFee: 1e14,
            maxToken1PurchaseFee: 1e18,
            token0PurchaseFee: 1e16,
            token1PurchaseFee: 5e16,
            initialAdminAddress: PROXY_ADMIN_OWNER,
            initialWhitelister: PROXY_ADMIN_OWNER,
            initialFeeSetter: PROXY_ADMIN_OWNER,
            initialTokenRemover: PROXY_ADMIN_OWNER,
            initialPauser: PROXY_ADMIN_OWNER,
            initialPriceSetter: PROXY_ADMIN_OWNER,
            initialTokenReceiver: PROXY_ADMIN_OWNER,
            initialFeeReceiver: PROXY_ADMIN_OWNER,
            minBasePrice: 9e17,
            maxBasePrice: 11e17,
            minAnnualizedInterestRate: 1e14,
            maxAnnualizedInterestRate: 1e18,
            basePrice: 1e18,
            annualizedInterestRate: 1e16
        });
        bytes memory _faucetInitialization = abi.encodeWithSelector(
            AgoraStableSwapPair.initialize.selector,
            _pairParams
        );

        console.log("AgoraStableSwapPair params encoded:");
        console.logBytes(_faucetInitialization);
    }

    modifier broadcaster() {
        vm.startBroadcast(HOTWALLET_DEPLOYER);
        _;
        vm.stopBroadcast();
    }
}
