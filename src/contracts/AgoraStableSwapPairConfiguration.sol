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

    function setManager(address _manager) public {
        // Checks: Only the owner can set the manager
        _requireSenderIsRole({ _role: "ACCESS_CONTROL_ADMIN_ROLE" });

        // emit event
        emit SetManager({ oldManager: _getPointerToStorage().configStorage.managerAddress, newManager: _manager });

        // Effects: Set the manager
        _getPointerToStorage().configStorage.managerAddress = _manager;
    }

    function _requireSenderIsManager() internal view {
        if (_getPointerToStorage().configStorage.managerAddress != msg.sender) revert SenderIsNotManager();
    }

    /// @notice The ```setTokenReceiver``` function sets the token receiver
    /// @param _tokenReceiver The address of the token receiver
    function setTokenReceiver(address _tokenReceiver) public {
        // Checks: Only the manager can set the token receiver
        _requireSenderIsManager();

        // Effects: Set the token receiver
        _getPointerToStorage().configStorage.tokenReceiverAddress = _tokenReceiver;

        // emit event
        emit SetTokenReceiver({ tokenReceiver: _tokenReceiver });
    }

    function setFeeReceiver(address _feeReceiver) public {
        // Checks: Only the manager can set the fee receiver
        _requireSenderIsManager();

        // Effects: Set the fee receiver
        _getPointerToStorage().configStorage.feeReceiverAddress = _feeReceiver;

        // emit event
        emit SetFeeReceiver({ feeReceiver: _feeReceiver });
    }

    function setTokenPurchaseFees(uint256 _token0PurchaseFee, uint256 _token1PurchaseFee) public {
        // Checks: Only the manager can set the fee
        _requireSenderIsManager();

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
        // Checks: Only the manager can remove tokens
        _requireSenderIsManager();

        SwapStorage memory _swapStorage = _getPointerToStorage().swapStorage;
        ConfigStorage memory _configStorage = _getPointerToStorage().configStorage;

        uint256 _token0Balance = IERC20(_swapStorage.token0).balanceOf(address(this));
        uint256 _token1Balance = IERC20(_swapStorage.token1).balanceOf(address(this));

        // Check for sufficient tokens available (we check the actual balance here instead of reserves)
        if (_tokenAddress == _swapStorage.token0 && _amount > _token0Balance - _swapStorage.token0FeesAccumulated) {
            revert InsufficientTokens();
        }
        if (_tokenAddress == _swapStorage.token1 && _amount > _token1Balance - _swapStorage.token1FeesAccumulated) {
            revert InsufficientTokens();
        }

        IERC20(_tokenAddress).safeTransfer({ to: _configStorage.tokenReceiverAddress, value: _amount });

        // Update reserves
        _sync({
            _token0Balance: IERC20(_swapStorage.token0).balanceOf(address(this)),
            _token1Balance: IERC20(_swapStorage.token1).balanceOf(address(this)),
            _token0FeesAccumulated: _swapStorage.token0FeesAccumulated,
            _token1FeesAccumulated: _swapStorage.token1FeesAccumulated
        });

        // emit event
        emit RemoveTokens({ tokenAddress: _tokenAddress, amount: _amount });
    }

    /// @notice The ```collectFees``` function removes accumulated fees from the pair
    /// @param _tokenAddress The address of the token
    /// @param _amount The amount of tokens to remove
    function collectFees(address _tokenAddress, uint256 _amount) external {
        // Checks: Only the manager can collect fees
        _requireSenderIsManager();

        SwapStorage memory _swapStorage = _getPointerToStorage().swapStorage;
        ConfigStorage memory _configStorage = _getPointerToStorage().configStorage;

        // Check for sufficient fees accumulated
        if (_tokenAddress == _swapStorage.token0 && _amount > _swapStorage.token0FeesAccumulated) {
            revert InsufficientTokens();
        }
        if (_tokenAddress == _swapStorage.token1 && _amount > _swapStorage.token1FeesAccumulated) {
            revert InsufficientTokens();
        }

        IERC20(_tokenAddress).safeTransfer({ to: _configStorage.feeReceiverAddress, value: _amount });

        // Calculate fees accumulated based on which token was transferred out
        if (_tokenAddress == _swapStorage.token0) {
            _swapStorage.token0FeesAccumulated -= _amount.toUint128();
        } else if (_tokenAddress == _swapStorage.token1) {
            _swapStorage.token1FeesAccumulated -= _amount.toUint128();
        } else {
            // If trying to remove a token not part of the pair, use the removeTokens function
            revert InvalidTokenAddress();
        }

        // Update reserves + fees accumulated
        _sync({
            _token0Balance: IERC20(_swapStorage.token0).balanceOf(address(this)),
            _token1Balance: IERC20(_swapStorage.token1).balanceOf(address(this)),
            _token0FeesAccumulated: _swapStorage.token0FeesAccumulated,
            _token1FeesAccumulated: _swapStorage.token1FeesAccumulated
        });

        // emit event
        emit CollectFees({ tokenAddress: _tokenAddress, amount: _amount });
    }

    /// @notice The ```setPaused``` function sets the paused state of the pair
    /// @param _setPaused The boolean value indicating whether the pair is paused
    function setPaused(bool _setPaused) public {
        // Checks: Only the manager can pause the pair
        _requireSenderIsManager();

        // Effects: Set the isPaused state
        _getPointerToStorage().swapStorage.isPaused = _setPaused;

        // emit event
        emit SetPaused({ isPaused: _setPaused });
    }

    /// @notice The ```configureOraclePrice``` function configures the price of the pair
    /// @dev Only the price setter can configure the price
    /// @param _basePrice The base price of the pair
    /// @param _annualizedInterestRate The annualized interest rate
    function configureOraclePrice(uint256 _basePrice, int256 _annualizedInterestRate) public {
        // Checks: Only the manager can configure the price
        _requireSenderIsManager();

        // Set the time of the last price update
        _getPointerToStorage().swapStorage.priceLastUpdated = (block.timestamp).toUint40();
        // Convert yearly APR to per second APR
        _getPointerToStorage().swapStorage.perSecondInterestRate = (_annualizedInterestRate / 365 days).toInt72();
        // Set the price of the asset
        _getPointerToStorage().swapStorage.basePrice = (_basePrice).toUint64();

        // emit eventd
        emit ConfigureOraclePrice(_basePrice, _annualizedInterestRate);
    }

    /// @notice The ```SetManager``` event is emitted when the manager is set
    /// @param oldManager The old manager
    /// @param newManager The new manager
    event SetManager(address indexed oldManager, address indexed newManager);

    /// @notice The ```SenderIsNotManager``` error is thrown when the sender is not the manager
    error SenderIsNotManager();

    /// @notice The ```CollectFees``` event is emitted when fees are collected
    /// @param tokenAddress The address of the token
    /// @param amount The amount of tokens collected
    event CollectFees(address indexed tokenAddress, uint256 amount);
}
