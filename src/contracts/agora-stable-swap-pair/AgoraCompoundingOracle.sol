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
// ===================== AgoraCompoundingOracle =======================
// ====================================================================

import { AgoraStableSwapAccessControl } from "./AgoraStableSwapAccessControl.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract AgoraCompoundingOracle is AgoraStableSwapAccessControl {
    using SafeCast for uint256;

    uint256 public constant PRECISION = 1e18;

    //==============================================================================
    // erc7201 Unstructured Storage
    //==============================================================================

    struct AgoraCompoundingOracleStorage {
        uint112 perSecondInterestRate; // The per second interest rate
        uint112 basePrice; // The base _token0OverToken1Price of the asset
        uint112 minPrice; // The minimum allowed _token0OverToken1Price
        uint112 maxPrice; // The maximum allowed _token0OverToken1Price
        uint112 minAnnualizedInterestRate; // The minimum allowed annualized interest rate
        uint112 maxAnnualizedInterestRate; // The maximum allowed annualized interest rate
        uint32 lastUpdated; // The timestamp of the last price update
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

    function _getCopyOfAgoraCompoundingOracleStorage()
        internal
        pure
        returns (AgoraCompoundingOracleStorage memory agoraCompoundingOracleStorage)
    {
        agoraCompoundingOracleStorage = _getPointerToAgoraCompoundingOracleStorage();
    }

    //==============================================================================
    // Initialization Functions
    //==============================================================================

    function _initializeAgoraCompoundingOracle() public {
        _getPointerToAgoraCompoundingOracleStorage().perSecondInterestRate = uint112(0);
        _getPointerToAgoraCompoundingOracleStorage().lastUpdated = (block.timestamp).toUint32();
        _getPointerToAgoraCompoundingOracleStorage().basePrice = uint112(1e18);
        // ! TODO: do we want smaller ranges on initialization here?
        _getPointerToAgoraCompoundingOracleStorage().minPrice = uint112(0);
        _getPointerToAgoraCompoundingOracleStorage().maxPrice = uint112(type(uint256).max);
        _getPointerToAgoraCompoundingOracleStorage().minAnnualizedInterestRate = uint112(0);
        _getPointerToAgoraCompoundingOracleStorage().maxAnnualizedInterestRate = uint112(type(uint256).max);
    }

    //==============================================================================
    // View Functions
    //==============================================================================

    event SetOraclePriceBounds(
        uint256 minPrice,
        uint256 maxPrice,
        uint256 minAnnualizedInterestRate,
        uint256 maxAnnualizedInterestRate
    );

    function configurePriceBounds(
        uint256 _minPrice,
        uint256 _maxPrice,
        uint256 _minAnnualizedInterestRate,
        uint256 _maxAnnualizedInterestRate
    ) external {
        _requireSenderIsRole({ _role: ADMIN_ROLE });
        // Check that the parameters are valid
        if (_minPrice >= _maxPrice) revert MinPriceGreaterThanMax();
        if (_minAnnualizedInterestRate >= _maxAnnualizedInterestRate) revert MinAnnualizedInterestRateGreaterThanMax();

        _getPointerToAgoraCompoundingOracleStorage().minPrice = (_minPrice).toUint112();
        _getPointerToAgoraCompoundingOracleStorage().maxPrice = (_maxPrice).toUint112();
        _getPointerToAgoraCompoundingOracleStorage().minAnnualizedInterestRate = (_minAnnualizedInterestRate)
            .toUint112();
        _getPointerToAgoraCompoundingOracleStorage().maxAnnualizedInterestRate = (_maxAnnualizedInterestRate)
            .toUint112();

        emit SetOraclePriceBounds({
            minPrice: _minPrice,
            maxPrice: _maxPrice,
            minAnnualizedInterestRate: _minAnnualizedInterestRate,
            maxAnnualizedInterestRate: _maxAnnualizedInterestRate
        });
    }

    event ConfigurePrice(uint256 basePrice, uint256 annualizedInterestRate);

    function configurePrice(uint256 _basePrice, uint256 _annualizedInterestRate) external {
        _requireSenderIsRole({ _role: PRICE_SETTER_ROLE });

        AgoraCompoundingOracleStorage memory _storage = _getCopyOfAgoraCompoundingOracleStorage();

        // Check that the price is within bounds
        if (_basePrice < _storage.minPrice || _basePrice > _storage.maxPrice) revert PriceOutOfBounds();
        if (
            _annualizedInterestRate < _storage.minAnnualizedInterestRate ||
            _annualizedInterestRate > _storage.maxAnnualizedInterestRate
        ) revert AnnualizedInterestRateOutOfBounds();

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

    /// @notice Emitted when the price is out of bounds
    error PriceOutOfBounds();

    /// @notice Emitted when the annualized interest rate is out of bounds
    error AnnualizedInterestRateOutOfBounds();

    /// @notice Emitted when the min price is greater than the max price
    error MinPriceGreaterThanMax();

    /// @notice Emitted when the min annualized interest rate is greater than the max annualized interest rate
    error MinAnnualizedInterestRateGreaterThanMax();
}
