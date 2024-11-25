// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { AgoraStableSwapAccessControl } from "./AgoraStableSwapAccessControl.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract AgoraCompoundingOracle is AgoraStableSwapAccessControl {
    using SafeCast for uint256;

    uint256 public constant PRECISION = 1e18;

    //==============================================================================
    // erc7201 Unstructured Storage
    //==============================================================================

    struct AgoraCompoundingOracleStorage {
        uint112 perSecondInterestRate;
        uint32 lastUpdated;
        uint112 basePrice;
    }

    /// @notice The ```ORACLE_STORAGE_SLOT``` is the storage slot for the CompoundingOracleStorage struct
    /// @dev keccak256(abi.encode(uint256(keccak256("AgoraStableSwapStorage.AgoraCompoundingOracleStorage") - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant AGORA_COMPOUNDING_ORACLE_STORAGE_SLOT =
        0xe8ff8c05fe4db6c989cd24f41a6017bb61bb3732b98d5e32412555322ce7a800;

    /// @notice The ```_getPointerToAgoraCompoundingOracleStorage``` function returns a pointer to the OracleStorage struct
    /// @return $ A pointer to the OracleStorage struct
    function _getPointerToAgoraCompoundingOracleStorage()
        internal
        pure
        returns (AgoraCompoundingOracleStorage storage $)
    {
        /// @solidity memory-safe-assembly
        assembly {
            $.slot := AGORA_COMPOUNDING_ORACLE_STORAGE_SLOT
        }
    }

    //==============================================================================
    // Initialization Functions
    //==============================================================================

    function _initializeAgoraCompoundingOracle() public {
        _getPointerToAgoraCompoundingOracleStorage().perSecondInterestRate = uint112(0);
        _getPointerToAgoraCompoundingOracleStorage().lastUpdated = (block.timestamp).toUint32();
        _getPointerToAgoraCompoundingOracleStorage().basePrice = uint112(1e18);
    }

    //==============================================================================
    // View Functions
    //==============================================================================

    event ConfigurePrice(uint256 basePrice, uint256 annualizedInterestRate);

    function configurePrice(uint256 _basePrice, uint256 _annualizedInterestRate) external {
        _requireSenderIsRole({ _role: PRICE_SETTER_ROLE });

        // Set the time of the last price update
        _getPointerToAgoraCompoundingOracleStorage().lastUpdated = (block.timestamp).toUint32();
        // Convert yearly APR to per second APR
        _getPointerToAgoraCompoundingOracleStorage().perSecondInterestRate = (_annualizedInterestRate / 365 days)
            .toUint112();
        // Set the price of the asset
        _getPointerToAgoraCompoundingOracleStorage().basePrice = (_basePrice).toUint112();

        // emit event
        emit ConfigurePrice(_basePrice, _annualizedInterestRate);
    }

    function getCompoundingPrice(
        uint256 _lastUpdated,
        uint256 _currentTimestamp,
        uint256 _interestRate,
        uint256 _basePrice
    ) public pure returns (uint256 _currentPrice) {
        // Calculate the time elapsed since the last price update
        uint256 timeElapsed = _currentTimestamp - _lastUpdated;
        // Calculate the compounded price
        _currentPrice = (_basePrice + _interestRate * timeElapsed);
    }

    function getPrice() public view virtual returns (uint256 _currentPrice) {
        AgoraCompoundingOracleStorage memory _storage = _getPointerToAgoraCompoundingOracleStorage();
        uint256 _lastUpdated = _storage.lastUpdated;
        uint256 _currentTimestamp = block.timestamp;
        uint256 _basePrice = _storage.basePrice;
        uint256 _interestRate = _storage.perSecondInterestRate;
        _currentPrice = getCompoundingPrice({
            _lastUpdated: _lastUpdated,
            _currentTimestamp: _currentTimestamp,
            _interestRate: _interestRate,
            _basePrice: _basePrice
        });
    }
}
