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
