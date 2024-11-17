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
// ====================== AgoraStableSwapPair =========================
// ====================================================================

import { AgoraStableSwapPairConfiguration } from "./AgoraStableSwapPairConfiguration.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title AgoraStableSwapPair
/// @notice The AgoraStableSwapPair is a contract that manages the core logic for the AgoraStableSwapPair
/// @author Agora
contract AgoraStableSwapPair is AgoraStableSwapPairConfiguration {
    using SafeERC20 for IERC20;

    /// @notice The ```token0``` function returns the address of the token0 in the pair
    /// @return _token0 The address of the token0 in the pair
    function token0() public view returns (address) {
        return _getPointerToStorage().swapStorage.token0;
    }

    /// @notice The ```token1``` function returns the address of the token1 in the pair
    /// @return _token1 The address of the token1 in the pair
    function token1() public view returns (address) {
        return _getPointerToStorage().swapStorage.token1;
    }

    /// @notice The ```token0PurchaseFee``` function returns the purchase fee for the token0 in the pair
    /// @return _token0PurchaseFee The purchase fee for the token0 in the pair
    function token0PurchaseFee() public view returns (uint256) {
        return _getPointerToStorage().swapStorage.token0PurchaseFee;
    }

    /// @notice The ```token1PurchaseFee``` function returns the purchase fee for the token1 in the pair
    /// @return _token1PurchaseFee The purchase fee for the token1 in the pair
    function token1PurchaseFee() public view returns (uint256) {
        return _getPointerToStorage().swapStorage.token1PurchaseFee;
    }

    /// @notice The ```isPaused``` function returns whether the pair is paused
    /// @return _isPaused Whether the pair is paused
    function isPaused() public view returns (bool) {
        return _getPointerToStorage().swapStorage.isPaused;
    }

    /// @notice The ```reserve0``` function returns the reserve of the token0 in the pair
    /// @return _reserve0 The reserve of the token0 in the pair
    function reserve0() public view returns (uint256) {
        return _getPointerToStorage().swapStorage.reserve0;
    }

    /// @notice The ```reserve1``` function returns the reserve of the token1 in the pair
    /// @return _reserve1 The reserve of the token1 in the pair
    function reserve1() public view returns (uint256) {
        return _getPointerToStorage().swapStorage.reserve1;
    }

    /// @notice The ```priceLastUpdated``` function returns the timestamp when the price was updated
    /// @return _priceLastUpdated The timestamp when the price was updated
    function priceLastUpdated() public view returns (uint256) {
        return _getPointerToStorage().swapStorage.priceLastUpdated;
    }

    /// @notice The ```perSecondInterestRate``` function returns the per second interest rate
    /// @return _perSecondInterestRate The per second interest rate
    function perSecondInterestRate() public view returns (uint256) {
        return _getPointerToStorage().swapStorage.perSecondInterestRate;
    }

    /// @notice The ```basePrice``` function returns the base price
    /// @return _basePrice The base price
    function basePrice() public view returns (uint256) {
        return _getPointerToStorage().swapStorage.basePrice;
    }

    /// @notice The ```minToken0PurchaseFee``` function returns the minimum purchase fee for token0
    /// @return _minToken0PurchaseFee The minimum purchase fee for token0
    function minToken0PurchaseFee() public view returns (uint256) {
        return _getPointerToStorage().configStorage.minToken0PurchaseFee;
    }

    /// @notice The ```maxToken0PurchaseFee``` function returns the maximum purchase fee for token0
    /// @return _maxToken0PurchaseFee The maximum purchase fee for token0
    function maxToken0PurchaseFee() public view returns (uint256) {
        return _getPointerToStorage().configStorage.maxToken0PurchaseFee;
    }

    /// @notice The ```minToken1PurchaseFee``` function returns the minimum purchase fee for token1
    /// @return _minToken1PurchaseFee The minimum purchase fee for token1
    function minToken1PurchaseFee() public view returns (uint256) {
        return _getPointerToStorage().configStorage.minToken1PurchaseFee;
    }

    /// @notice The ```maxToken1PurchaseFee``` function returns the maximum purchase fee for token1
    /// @return _maxToken1PurchaseFee The maximum purchase fee for token1
    function maxToken1PurchaseFee() public view returns (uint256) {
        return _getPointerToStorage().configStorage.maxToken1PurchaseFee;
    }

    /// @notice The ```tokenReceiverAddress``` function returns the address of the token receiver
    /// @return _tokenReceiverAddress The address of the token receiver
    function tokenReceiverAddress() public view returns (address) {
        return _getPointerToStorage().configStorage.tokenReceiverAddress;
    }

    /// @notice The ```minBasePrice``` function returns the minimum base price
    /// @return _minBasePrice The minimum base price
    function minBasePrice() public view returns (uint256) {
        return _getPointerToStorage().configStorage.minBasePrice;
    }

    /// @notice The ```maxBasePrice``` function returns the maximum base price
    /// @return _maxBasePrice The maximum base price
    function maxBasePrice() public view returns (uint256) {
        return _getPointerToStorage().configStorage.maxBasePrice;
    }

    /// @notice The ```minAnnualizedInterestRate``` function returns the minimum annualized interest rate
    /// @return _minAnnualizedInterestRate The minimum annualized interest rate
    function minAnnualizedInterestRate() public view returns (uint256) {
        return _getPointerToStorage().configStorage.minAnnualizedInterestRate;
    }

    /// @notice The ```maxAnnualizedInterestRate``` function returns the maximum annualized interest rate
    /// @return _maxAnnualizedInterestRate The maximum annualized interest rate
    function maxAnnualizedInterestRate() public view returns (uint256) {
        return _getPointerToStorage().configStorage.maxAnnualizedInterestRate;
    }

    /// @notice The ```getAmountsOut``` function calculates the amount of tokenOut returned from a given amount of tokenIn
    /// @param _empty empty variable to adhere to uniswapV2 interface, normally contains factory address
    /// @param _amountIn The amount of input tokenIn
    /// @param _path The path of the tokens
    /// @return _amounts The amount of returned output tokenOut
    function getAmountsOut(
        address _empty,
        uint256 _amountIn,
        address[] memory _path
    ) public view returns (uint256[] memory _amounts) {
        SwapStorage memory _storage = _getPointerToStorage().swapStorage;
        uint256 _token0OverToken1Price = getPrice();

        // Checks: path length is 2 && path must contain token0 and token1 only
        requireValidPath({ _path: _path, _token0: _storage.token0, _token1: _storage.token1 });

        // Checks: amountIn is greater than 0
        if (_amountIn == 0) revert InsufficientInputAmount();

        // instantiate return variables
        _amounts = new uint256[](2);
        _amounts[0] = _amountIn;

        // path[1] represents our tokenOut
        if (_path[1] == _storage.token0) {
            _amounts[1] = getAmount0Out({
                _amountIn: _amountIn,
                _token0OverToken1Price: _token0OverToken1Price,
                _token0PurchaseFee: _storage.token0PurchaseFee
            });
        } else {
            _amounts[1] = getAmount1Out({
                _amountIn: _amountIn,
                _token0OverToken1Price: _token0OverToken1Price,
                _token1PurchaseFee: _storage.token1PurchaseFee
            });
        }
    }

    /// @notice The ```getAmountsIn``` function calculates the amount of input tokensIn required for a given amount tokensOut
    /// @param _empty empty variable to adhere to uniswapV2 interface, normally contains factory address
    /// @param _amountOut The amount of output tokenOut
    /// @param _path The path of the tokens
    /// @return _amounts The amount of required input tokenIn
    function getAmountsIn(
        address _empty,
        uint256 _amountOut,
        address[] memory _path
    ) public view returns (uint256[] memory _amounts) {
        SwapStorage memory _storage = _getPointerToStorage().swapStorage;
        uint256 _token0OverToken1Price = getPrice();

        // Checks: path length is 2 && path must contain token0 and token1 only
        requireValidPath({ _path: _path, _token0: _storage.token0, _token1: _storage.token1 });

        // Checks: amountOut is greater than 0
        if (_amountOut == 0) revert InsufficientOutputAmount();

        // instantiate return variables
        _amounts = new uint256[](2);
        // set the amountOut
        _amounts[1] = _amountOut;

        // path[0] represents our tokenIn
        if (_path[0] == _storage.token0) {
            _amounts[0] = getAmount0In({
                _amountOut: _amountOut,
                _token0OverToken1Price: _token0OverToken1Price,
                _token1PurchaseFee: _storage.token1PurchaseFee
            });
        } else {
            _amounts[0] = getAmount1In({
                _amountOut: _amountOut,
                _token0OverToken1Price: _token0OverToken1Price,
                _token0PurchaseFee: _storage.token0PurchaseFee
            });
        }
    }

    /// @notice The ```getPriceNormalized``` function returns a price in a human-readable format adjusting for differences in precision
    /// @return _normalizedPrice The normalized price with 18 decimals of precision
    function getPriceNormalized() external view returns (uint256 _normalizedPrice) {
        ConfigStorage memory _configStorage = _getPointerToStorage().configStorage;
        return (getPrice() * 10 ** _configStorage.token1Decimals) / 10 ** _configStorage.token0Decimals;
    }

    /// @notice The ```Version``` struct is used to represent the version of the AgoraStableSwapPair
    /// @param major The major version number
    /// @param minor The minor version number
    /// @param patch The patch version number
    struct Version {
        uint256 major;
        uint256 minor;
        uint256 patch;
    }

    /// @notice The ```version``` function returns the version of the AgoraStableSwapPair
    /// @return _version The version of the AgoraStableSwapPair
    function version() external pure returns (Version memory _version) {
        _version = Version({ major: 1, minor: 0, patch: 0 });
    }
}
