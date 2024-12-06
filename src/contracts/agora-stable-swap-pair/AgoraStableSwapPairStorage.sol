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

/// @notice The AgoraStableSwapPairStorage contract is used to store the state of the AgoraStableSwapPair contract
/// @dev This contract is used to store the state of the AgoraStableSwapPair contract
/// @author Agora
contract AgoraStableSwapPairStorage {
    //==============================================================================
    // Structs
    //==============================================================================
    struct ConfigStorage {
        uint256 minToken0PurchaseFee; // given as bps with 1 decimal (i.e. 1000 = 100 bps = 1%)
        uint256 maxToken0PurchaseFee; // given as bps with 1 decimal (i.e. 1000 = 100 bps = 1%)
        uint256 minToken1PurchaseFee; // given as bps with 1 decimal (i.e. 1000 = 100 bps = 1%)
        uint256 maxToken1PurchaseFee; // given as bps with 1 decimal (i.e. 1000 = 100 bps = 1%)
        address tokenReceiverAddress;
        uint256 minBasePrice;
        uint256 maxBasePrice;
        uint256 minAnnualizedInterestRate;
        uint256 maxAnnualizedInterestRate;
    }

    struct SwapStorage {
        bool isPaused;
        address token0;
        uint8 token0Decimals;
        address token1;
        uint8 token1Decimals;
        uint112 reserve0;
        uint112 reserve1;
        uint64 token0PurchaseFee; // 18 decimals precision, max value 1
        uint64 token1PurchaseFee; // 18 decimals precision, max value 1
        uint32 priceLastUpdated; // Only good for a few more years
        uint64 perSecondInterestRate; // 18 decimals of precision
        uint256 basePrice; // 18 decimals of precision
    }

    /// @notice The AgoraStableSwapStorage struct is used to store the state of the AgoraStableSwapPair contract
    /// @param token0 The address of token0
    /// @param token1 The address of token1
    /// @param token0PurchaseFee The purchase fee for token0
    /// @param minToken0PurchaseFee The minimum purchase fee for token0
    /// @param maxToken0PurchaseFee The maximum purchase fee for token0
    /// @param token1PurchaseFee The purchase fee for token1
    /// @param minToken1PurchaseFee The minimum purchase fee for token1
    /// @param maxToken1PurchaseFee The maximum purchase fee for token1
    /// @param oracleAddress The address of the oracle
    /// @param reserve0 The reserve of token0
    /// @param reserve1 The reserve of token1
    /// @param lastBlock The last block number
    /// @param isPaused The boolean value indicating whether the pair is paused
    /// @param tokenReceiverAddress The address of the token receiver
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
    function getPointerToAgoraStableSwapStorage() public pure returns (AgoraStableSwapStorage storage $) {
        /// @solidity memory-safe-assembly
        assembly {
            $.slot := AGORA_STABLE_SWAP_STORAGE_SLOT
        }
    }

    /// @notice The ```AGORA_STABLE_SWAP_TRANSIENT_LOCK_SLOT``` is the storage slot for the re-entrancy lock
    /// @dev keccak256(abi.encode(uint256(keccak256("AgoraStableSwapStorage.TransientReentrancyLock")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant AGORA_STABLE_SWAP_TRANSIENT_LOCK_SLOT =
        0x1c912e2d5b9a8ca13ccf418e7dc8bfe55d8292938ebaef5b3166abbe45f04b00;
}
