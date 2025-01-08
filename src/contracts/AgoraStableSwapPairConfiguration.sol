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
// ================ AgoraStableSwapPairConfiguration ===================
// ====================================================================

import { AgoraStableSwapPairCore } from "./AgoraStableSwapPairCore.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @title AgoraStableSwapPairConfiguration
/// @notice The AgoraStableSwapPairConfiguration is a contract that manages the privileged configuration setters for the AgoraStableSwapPair
/// @author Agora
contract AgoraStableSwapPairConfiguration is AgoraStableSwapPairCore {
    using SafeCast for *;
    using SafeERC20 for IERC20;

    //==============================================================================
    // Privileged Configuration Functions
    //==============================================================================

    /// @notice The ```setTokenReceiver``` function sets the token receiver
    /// @param _tokenReceiver The address of the token receiver
    function setTokenReceiver(address _tokenReceiver) public {
        // Checks: Only the admin can set the token receiver
        _requireIsRole({ _role: ADMIN_ROLE, _address: msg.sender });

        // Effects: Set the token receiver
        _getPointerToStorage().configStorage.tokenReceiverAddress = _tokenReceiver;

        // emit event
        emit SetTokenReceiver({ tokenReceiver: _tokenReceiver });
    }

    /// @notice The ```setApprovedSwapper``` function sets the approved swapper
    /// @param _approvedSwapper The address of the approved swapper
    /// @param _setApproved The boolean value indicating whether the swapper is approved
    function setApprovedSwapper(address _approvedSwapper, bool _setApproved) public {
        // Checks: Only the whitelister can set the approved swapper
        _requireIsRole({ _role: WHITELISTER_ROLE, _address: msg.sender });

        // Effects: Set the isApproved state
        _assignRole({ _role: APPROVED_SWAPPER, _newAddress: _approvedSwapper, _addRole: _setApproved });

        // emit event
        emit SetApprovedSwapper({ approvedSwapper: _approvedSwapper, isApproved: _setApproved });
    }

    /// @notice The ```setFeeBounds``` function sets the fee bounds
    /// @param minToken0PurchaseFee The minimum purchase fee for token0
    /// @param maxToken0PurchaseFee The maximum purchase fee for token0
    /// @param minToken1PurchaseFee The minimum purchase fee for token1
    /// @param maxToken1PurchaseFee The maximum purchase fee for token1
    function setFeeBounds(
        uint256 minToken0PurchaseFee,
        uint256 maxToken0PurchaseFee,
        uint256 minToken1PurchaseFee,
        uint256 maxToken1PurchaseFee
    ) external {
        // Checks: Only the admin can set the fee bounds
        _requireSenderIsRole({ _role: ADMIN_ROLE });

        // Effects: Set the fee bounds
        _getPointerToStorage().configStorage.minToken0PurchaseFee = minToken0PurchaseFee;
        _getPointerToStorage().configStorage.maxToken0PurchaseFee = maxToken0PurchaseFee;
        _getPointerToStorage().configStorage.minToken1PurchaseFee = minToken1PurchaseFee;
        _getPointerToStorage().configStorage.maxToken1PurchaseFee = maxToken1PurchaseFee;

        emit SetFeeBounds({
            minToken0PurchaseFee: minToken0PurchaseFee,
            maxToken0PurchaseFee: maxToken0PurchaseFee,
            minToken1PurchaseFee: minToken1PurchaseFee,
            maxToken1PurchaseFee: maxToken1PurchaseFee
        });
    }

    function setTokenPurchaseFees(uint256 _token0PurchaseFee, uint256 _token1PurchaseFee) public {
        // Checks: Only the fee setter can set the fee
        _requireIsRole({ _role: FEE_SETTER_ROLE, _address: msg.sender });

        // Checks: Ensure the params are valid and within the bounds
        if (
            _token0PurchaseFee < _getPointerToStorage().configStorage.minToken0PurchaseFee ||
            _token0PurchaseFee > _getPointerToStorage().configStorage.maxToken0PurchaseFee
        ) revert InvalidToken0PurchaseFee();
        if (
            _token1PurchaseFee < _getPointerToStorage().configStorage.minToken1PurchaseFee ||
            _token1PurchaseFee > _getPointerToStorage().configStorage.maxToken1PurchaseFee
        ) revert InvalidToken1PurchaseFee();

        // Effects: write to storage
        _getPointerToStorage().swapStorage.token0PurchaseFee = _token0PurchaseFee.toUint64();
        _getPointerToStorage().swapStorage.token1PurchaseFee = _token1PurchaseFee.toUint64();

        // emit event
        emit SetTokenPurchaseFees({ token0PurchaseFee: _token0PurchaseFee, token1PurchaseFee: _token1PurchaseFee });
    }

    /// @notice The ```removeTokens``` function removes tokens from the pair
    /// @param _tokenAddress The address of the token
    /// @param _amount The amount of tokens to remove
    function removeTokens(address _tokenAddress, uint256 _amount) external {
        // Checks: Only the token remover can remove tokens
        _requireIsRole({ _role: TOKEN_REMOVER_ROLE, _address: msg.sender });

        SwapStorage memory _swapStorage = _getPointerToStorage().swapStorage;
        ConfigStorage memory _configStorage = _getPointerToStorage().configStorage;

        IERC20(_tokenAddress).safeTransfer({ to: _configStorage.tokenReceiverAddress, value: _amount });

        // Update reserves
        _sync({
            _token0balance: IERC20(_swapStorage.token0).balanceOf(address(this)),
            _token1Balance: IERC20(_swapStorage.token1).balanceOf(address(this))
        });

        // emit event
        emit RemoveTokens({ tokenAddress: _tokenAddress, amount: _amount });
    }

    /// @notice The ```setPaused``` function sets the paused state of the pair
    /// @param _setPaused The boolean value indicating whether the pair is paused
    function setPaused(bool _setPaused) public {
        // Checks: Only the pauser can pause the pair
        _requireIsRole({ _role: PAUSER_ROLE, _address: msg.sender });

        // Effects: Set the isPaused state
        _getPointerToStorage().swapStorage.isPaused = _setPaused;

        // emit event
        emit SetPaused({ isPaused: _setPaused });
    }

    /// @notice The ```setOraclePriceBounds``` function sets the price bounds for the pair
    /// @dev Only the admin can set the price bounds
    /// @param _minBasePrice The minimum allowed initial base price
    /// @param _maxBasePrice The maximum allowed initial base price
    /// @param _minAnnualizedInterestRate The minimum allowed annualized interest rate
    /// @param _maxAnnualizedInterestRate The maximum allowed annualized interest rate
    function setOraclePriceBounds(
        uint256 _minBasePrice,
        uint256 _maxBasePrice,
        int256 _minAnnualizedInterestRate,
        int256 _maxAnnualizedInterestRate
    ) external {
        _requireSenderIsRole({ _role: ADMIN_ROLE });
        // Check that the parameters are valid
        if (_minBasePrice > _maxBasePrice) revert MinBasePriceGreaterThanMaxBasePrice();
        if (_minAnnualizedInterestRate > _maxAnnualizedInterestRate) revert MinAnnualizedInterestRateGreaterThanMax();

        _getPointerToStorage().configStorage.minBasePrice = _minBasePrice;
        _getPointerToStorage().configStorage.maxBasePrice = _maxBasePrice;
        _getPointerToStorage().configStorage.minAnnualizedInterestRate = _minAnnualizedInterestRate;
        _getPointerToStorage().configStorage.maxAnnualizedInterestRate = _maxAnnualizedInterestRate;

        emit SetOraclePriceBounds({
            minBasePrice: _minBasePrice,
            maxBasePrice: _maxBasePrice,
            minAnnualizedInterestRate: _minAnnualizedInterestRate,
            maxAnnualizedInterestRate: _maxAnnualizedInterestRate
        });
    }

    /// @notice The ```configureOraclePrice``` function configures the price of the pair
    /// @dev Only the price setter can configure the price
    /// @param _basePrice The base price of the pair
    /// @param _annualizedInterestRate The annualized interest rate
    function configureOraclePrice(uint256 _basePrice, int256 _annualizedInterestRate) external {
        _requireSenderIsRole({ _role: PRICE_SETTER_ROLE });

        ConfigStorage memory _storage = _getPointerToStorage().configStorage;

        // Check that the price is within bounds
        if (_basePrice < _storage.minBasePrice || _basePrice > _storage.maxBasePrice) revert BasePriceOutOfBounds();
        if (
            _annualizedInterestRate < _storage.minAnnualizedInterestRate ||
            _annualizedInterestRate > _storage.maxAnnualizedInterestRate
        ) revert AnnualizedInterestRateOutOfBounds();

        // Set the time of the last price update
        _getPointerToStorage().swapStorage.priceLastUpdated = (block.timestamp).toUint40();
        // Convert yearly APR to per second APR
        _getPointerToStorage().swapStorage.perSecondInterestRate = (_annualizedInterestRate / 365 days).toInt72();
        // Set the price of the asset
        _getPointerToStorage().swapStorage.basePrice = (_basePrice).toUint64();

        // emit eventd
        emit ConfigureOraclePrice(_basePrice, _annualizedInterestRate);
    }
}
