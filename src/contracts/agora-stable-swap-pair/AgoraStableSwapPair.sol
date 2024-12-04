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

import { AgoraStableSwapPairCore } from "./AgoraStableSwapPairCore.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title AgoraStableSwapPair
/// @notice The AgoraStableSwapPair is a contract that manages the core logic for the AgoraStableSwapPair
/// @author Agora
contract AgoraStableSwapPair is AgoraStableSwapPairCore {
    using SafeERC20 for IERC20;

    /// @notice The ```token0``` function returns the address of the token0 in the pair
    /// @return _token0 The address of the token0 in the pair
    function token0() public view returns (address) {
        return _getPointerToAgoraStableSwapStorage().swapStorage.token0;
    }

    /// @notice The ```token1``` function returns the address of the token1 in the pair
    /// @return _token1 The address of the token1 in the pair
    function token1() public view returns (address) {
        return _getPointerToAgoraStableSwapStorage().swapStorage.token1;
    }

    /// @notice The ```token0PurchaseFee``` function returns the purchase fee for the token0 in the pair
    /// @return _token0PurchaseFee The purchase fee for the token0 in the pair
    function token0PurchaseFee() public view returns (uint256) {
        return _getPointerToAgoraStableSwapStorage().swapStorage.token0PurchaseFee;
    }

    /// @notice The ```token1PurchaseFee``` function returns the purchase fee for the token1 in the pair
    /// @return _token1PurchaseFee The purchase fee for the token1 in the pair
    function token1PurchaseFee() public view returns (uint256) {
        return _getPointerToAgoraStableSwapStorage().swapStorage.token1PurchaseFee;
    }

    /// @notice The ```isPaused``` function returns whether the pair is paused
    /// @return _isPaused Whether the pair is paused
    function isPaused() public view returns (bool) {
        return _getPointerToAgoraStableSwapStorage().swapStorage.isPaused;
    }

    /// @notice The ```token0OverToken1Price``` function returns the price of the pair expressed as token0 over token1
    /// @return _token0OverToken1Price The price of the pair expressed as token0 over token1
    function token0OverToken1Price() public view returns (uint256) {
        return _getPointerToAgoraStableSwapStorage().swapStorage.token0OverToken1Price;
    }

    /// @notice The ```reserve0``` function returns the reserve of the token0 in the pair
    /// @return _reserve0 The reserve of the token0 in the pair
    function reserve0() public view returns (uint256) {
        return _getPointerToAgoraStableSwapStorage().swapStorage.reserve0;
    }

    /// @notice The ```reserve1``` function returns the reserve of the token1 in the pair
    /// @return _reserve1 The reserve of the token1 in the pair
    function reserve1() public view returns (uint256) {
        return _getPointerToAgoraStableSwapStorage().swapStorage.reserve1;
    }

    /// @notice The ```getAmountsOut``` function calculates the amount of tokenOut returned from a given amount of tokenIn
    /// @param _empty The address of the empty address // ! TODO: check if this is correct
    /// @param _amountIn The amount of input tokenIn
    /// @param _path The path of the tokens
    /// @return _amounts The amount of returned output tokenOut
    function getAmountsOut(
        address _empty,
        uint256 _amountIn,
        address[] memory _path
    ) public view returns (uint256[] memory _amounts) {
        SwapStorage memory _storage = _getPointerToAgoraStableSwapStorage().swapStorage;
        uint256 _token0OverToken1Price = getPrice();

        // Checks: path length is 2 && path must contain token0 and token1 only
        _requireValidPath({ _path: _path, _token0: _storage.token0, _token1: _storage.token1 });

        // instantiate return variables
        _amounts = new uint256[](2);
        _amounts[0] = _amountIn;

        // path[1] represents our tokenOut
        if (_path[1] == _storage.token0) {
            _amounts[1] = _getAmount0Out({
                _amountIn: _amountIn,
                _token0OverToken1Price: _token0OverToken1Price,
                _token0PurchaseFee: _storage.token0PurchaseFee
            });
        } else {
            _amounts[1] = _getAmount1Out({
                _amountIn: _amountIn,
                _token0OverToken1Price: _token0OverToken1Price,
                _token1PurchaseFee: _storage.token1PurchaseFee
            });
        }
    }

    /// @notice The ```getAmountsIn``` function calculates the amount of input tokensIn required for a given amount tokensOut
    /// @param _empty The address of the empty address // ! TODO: check if this is correct
    /// @param _amountOut The amount of output tokenOut
    /// @param _path The path of the tokens
    /// @return _amounts The amount of required input tokenIn
    function getAmountsIn(
        address _empty,
        uint256 _amountOut,
        address[] memory _path
    ) public view returns (uint256[] memory _amounts) {
        SwapStorage memory _storage = _getPointerToAgoraStableSwapStorage().swapStorage;
        uint256 _token0OverToken1Price = getPrice();

        // Checks: path length is 2 && path must contain token0 and token1 only
        _requireValidPath({ _path: _path, _token0: _storage.token0, _token1: _storage.token1 });

        // instantiate return variables
        _amounts = new uint256[](2);
        // set the amountOut
        _amounts[1] = _amountOut;

        // path[0] represents our tokenIn
        if (_path[0] == _storage.token0) {
            _amounts[0] = _getAmount0In({
                _amountOut: _amountOut,
                _token0OverToken1Price: _token0OverToken1Price,
                _token0PurchaseFee: _storage.token0PurchaseFee
            });
        } else {
            _amounts[0] = _getAmount1In({
                _amountOut: _amountOut,
                _token0OverToken1Price: _token0OverToken1Price,
                _token1PurchaseFee: _storage.token1PurchaseFee
            });
        }
    }
}
