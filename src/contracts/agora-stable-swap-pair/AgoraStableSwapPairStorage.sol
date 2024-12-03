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
// =================== AgoraStableSwapPairStorage =====================
// ====================================================================

contract AgoraStableSwapPairStorage {
    //==============================================================================
    // Structs
    //==============================================================================
    struct ConfigStorage {
        uint256 minToken0PurchaseFee; // 18 decimals
        uint256 maxToken0PurchaseFee; // 18 decimals
        uint256 minToken1PurchaseFee; // 18 decimals
        uint256 maxToken1PurchaseFee; // 18 decimals
        address tokenReceiverAddress;
    }

    struct SwapStorage {
        bool isPaused;
        address token0;
        address token1;
        uint112 reserve0;
        uint112 reserve1;
        uint16 token0PurchaseFee; // given as bps with 1 decimal (i.e. 1000 = 100 bps = 1%)
        uint16 token1PurchaseFee; // given as bps with 1 decimal (i.e. 1000 = 100 bps = 1%)
        uint40 priceLastUpdated;
        uint128 token0OverToken1Price; // given as token1's price in token0 with 18 decimals
    }

    /// @notice The AgoraStableSwapStorage struct is used to store the state of the AgoraStableSwapPair contract
    struct AgoraStableSwapStorage {
        SwapStorage swapStorage;
        ConfigStorage config;
    }

    //==============================================================================
    // Erc 7201: UnstructuredNamespace Storage Functions
    //==============================================================================

    /// @notice The ```AGORA_STABLE_SWAP_STORAGE_SLOT``` is the storage slot for the AgoraStableSwapStorage struct
    /// @dev keccak256(abi.encode(uint256(keccak256("AgoraStableSwapPairStorage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant AGORA_STABLE_SWAP_STORAGE_SLOT =
        0x7bec511bd7f6687e2731c8fe683a8e6468bf371b3ebd503eee87dd5465b4a500;

    /// @notice The ```_getPointerToAgoraStableSwapStorage``` function returns a pointer to the AgoraStableSwapStorage struct
    /// @return $ A pointer to the AgoraStableSwapStorage struct
    function _getPointerToAgoraStableSwapStorage() internal pure returns (AgoraStableSwapStorage storage $) {
        /// @solidity memory-safe-assembly
        assembly {
            $.slot := AGORA_STABLE_SWAP_STORAGE_SLOT
        }
    }

    function _getCopyOfAgoraStableSwapStorage()
        internal
        pure
        returns (AgoraStableSwapStorage memory agoraStableSwapStorage)
    {
        agoraStableSwapStorage = _getPointerToAgoraStableSwapStorage();
    }

    /// @notice The ```AGORA_STABLE_SWAP_TRANSIENT_LOCK_SLOT``` is the storage slot for the re-entrancy lock
    /// @dev keccak256(abi.encode(uint256(keccak256("AgoraStableSwapStorage.TransientReentrancyLock")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant AGORA_STABLE_SWAP_TRANSIENT_LOCK_SLOT =
        0x1c912e2d5b9a8ca13ccf418e7dc8bfe55d8292938ebaef5b3166abbe45f04b00;
}
