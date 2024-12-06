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

//! TODO: this contract actually uses a linear increase in price over time, not compounding

/// @title AgoraCompoundingOracle
/// @notice The AgoraCompoundingOracle is a contract that manages the price of a pair
/// @dev The price accrues with a simple compounding model, updated using per second interest rate
/// @author Agora
contract AgoraCompoundingOracle is AgoraStableSwapAccessControl {
    using SafeCast for uint256;

    uint256 public constant PRECISION = 1e18;

    //==============================================================================
    // erc7201 Unstructured Storage
    //==============================================================================

    /// @notice The ```AgoraCompoundingOracleStorage``` struct
    /// @param perSecondInterestRate The per second interest rate
    /// @param basePrice The base price of the pair expressed as _token0OverToken1Price
    /// @param minBasePrice The minimum allowed initial base price
    /// @param maxBasePrice The maximum allowed initial base price
    /// @param minAnnualizedInterestRate The minimum allowed annualized interest rate
    /// @param maxAnnualizedInterestRate The maximum allowed annualized interest rate
    /// @param lastUpdated The timestamp of the last price update
    struct AgoraCompoundingOracleStorage {
        uint112 perSecondInterestRate;
        uint112 basePrice;
        uint112 minBasePrice;
        uint112 maxBasePrice;
        uint112 minAnnualizedInterestRate;
        uint112 maxAnnualizedInterestRate;
        uint32 lastUpdated;
    }

    /// @notice The ```AGORA_COMPOUNDING_ORACLE_STORAGE_SLOT``` is the storage slot for the CompoundingOracleStorage struct
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

    /// @notice The ```_initializeAgoraCompoundingOracle``` function initializes the AgoraCompoundingOracleStorage struct
    /// @dev initialization is called on the same transaction as the deployment of the pair
    function _initializeAgoraCompoundingOracle() internal {
        _getPointerToAgoraCompoundingOracleStorage().perSecondInterestRate = uint112(0);
        _getPointerToAgoraCompoundingOracleStorage().lastUpdated = (block.timestamp).toUint32();
        _getPointerToAgoraCompoundingOracleStorage().basePrice = uint112(1e18);
    }

    //==============================================================================
    // View Functions
    //==============================================================================

    /// @notice Emitted when the price bounds are set
    /// @param minBasePrice The minimum allowed initial base price
    /// @param maxBasePrice The maximum allowed initial base price
    /// @param minAnnualizedInterestRate The minimum allowed annualized interest rate
    /// @param maxAnnualizedInterestRate The maximum allowed annualized interest rate
    event SetOraclePriceBounds(
        uint256 minBasePrice,
        uint256 maxBasePrice,
        uint256 minAnnualizedInterestRate,
        uint256 maxAnnualizedInterestRate
    );

    /// @notice The ```setOraclePriceBounds``` function sets the price bounds for the pair
    /// @dev Only the admin can set the price bounds
    /// @param _minBasePrice The minimum allowed initial base price
    /// @param _maxBasePrice The maximum allowed initial base price
    /// @param _minAnnualizedInterestRate The minimum allowed annualized interest rate
    /// @param _maxAnnualizedInterestRate The maximum allowed annualized interest rate
    function setOraclePriceBounds(
        uint256 _minBasePrice,
        uint256 _maxBasePrice,
        uint256 _minAnnualizedInterestRate,
        uint256 _maxAnnualizedInterestRate
    ) external {
        _requireSenderIsRole({ _role: ADMIN_ROLE });
        // Check that the parameters are valid
        if (_minBasePrice >= _maxBasePrice) revert MinBasePriceGreaterThanMaxBasePrice();
        if (_minAnnualizedInterestRate >= _maxAnnualizedInterestRate) revert MinAnnualizedInterestRateGreaterThanMax();

        _getPointerToAgoraCompoundingOracleStorage().minBasePrice = (_minBasePrice).toUint112();
        _getPointerToAgoraCompoundingOracleStorage().maxBasePrice = (_maxBasePrice).toUint112();
        _getPointerToAgoraCompoundingOracleStorage().minAnnualizedInterestRate = (_minAnnualizedInterestRate)
            .toUint112();
        _getPointerToAgoraCompoundingOracleStorage().maxAnnualizedInterestRate = (_maxAnnualizedInterestRate)
            .toUint112();

        emit SetOraclePriceBounds({
            minBasePrice: _minBasePrice,
            maxBasePrice: _maxBasePrice,
            minAnnualizedInterestRate: _minAnnualizedInterestRate,
            maxAnnualizedInterestRate: _maxAnnualizedInterestRate
        });
    }

    /// @notice Emitted when the price is configured
    /// @param basePrice The base price of the pair
    /// @param annualizedInterestRate The annualized interest rate
    event ConfigureOraclePrice(uint256 basePrice, uint256 annualizedInterestRate);

    /// @notice The ```configureOraclePrice``` function configures the price of the pair
    /// @dev Only the price setter can configure the price
    /// @param _basePrice The base price of the pair
    /// @param _annualizedInterestRate The annualized interest rate
    function configureOraclePrice(uint256 _basePrice, uint256 _annualizedInterestRate) external {
        _requireSenderIsRole({ _role: PRICE_SETTER_ROLE });

        AgoraCompoundingOracleStorage memory _storage = _getPointerToAgoraCompoundingOracleStorage();

        // Check that the price is within bounds
        if (_basePrice < _storage.minBasePrice || _basePrice > _storage.maxBasePrice) revert BasePriceOutOfBounds();
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
        emit ConfigureOraclePrice(_basePrice, _annualizedInterestRate);
    }

    /// @notice The ```calculatePrice``` function calculates the current price of the pair using a simple compounding model
    /// @param _lastUpdated The timestamp of the last price update
    /// @param _currentTimestamp The current timestamp
    /// @param _interestRate The per second interest rate
    /// @param _basePrice The base price of the pair
    /// @return _currentPrice The current price of the pair
    function calculatePrice(
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

    /// @notice The ```getPrice``` function returns the current price of the pair
    /// @return _currentPrice The current price of the pair
    function getPrice() public view virtual returns (uint256 _currentPrice) {
        AgoraCompoundingOracleStorage memory _storage = _getPointerToAgoraCompoundingOracleStorage();
        uint256 _lastUpdated = _storage.lastUpdated;
        uint256 _currentTimestamp = block.timestamp;
        uint256 _basePrice = _storage.basePrice;
        uint256 _interestRate = _storage.perSecondInterestRate;
        _currentPrice = calculatePrice({
            _lastUpdated: _lastUpdated,
            _currentTimestamp: _currentTimestamp,
            _interestRate: _interestRate,
            _basePrice: _basePrice
        });
    }

    /// @notice Emitted when the price is out of bounds
    error BasePriceOutOfBounds();

    /// @notice Emitted when the annualized interest rate is out of bounds
    error AnnualizedInterestRateOutOfBounds();

    /// @notice Emitted when the min base price is greater than the max base price
    error MinBasePriceGreaterThanMaxBasePrice();

    /// @notice Emitted when the min annualized interest rate is greater than the max annualized interest rate
    error MinAnnualizedInterestRateGreaterThanMax();
}
