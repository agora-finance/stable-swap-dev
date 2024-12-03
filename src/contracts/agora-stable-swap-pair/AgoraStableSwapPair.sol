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

contract AgoraStableSwapPair is AgoraStableSwapPairCore {
    using SafeERC20 for IERC20;

    function token0() public view returns (address) {
        return _getPointerToAgoraStableSwapStorage().swapStorage.token0;
    }

    function token1() public view returns (address) {
        return _getPointerToAgoraStableSwapStorage().swapStorage.token1;
    }

    function token0PurchaseFee() public view returns (uint256) {
        return _getPointerToAgoraStableSwapStorage().swapStorage.token0PurchaseFee;
    }

    function token1PurchaseFee() public view returns (uint256) {
        return _getPointerToAgoraStableSwapStorage().swapStorage.token1PurchaseFee;
    }

    function isPaused() public view returns (bool) {
        return _getPointerToAgoraStableSwapStorage().swapStorage.isPaused;
    }

    function token0OverToken1Price() public view returns (uint256) {
        return _getPointerToAgoraStableSwapStorage().swapStorage.token0OverToken1Price;
    }

    function reserve0() public view returns (uint256) {
        return _getPointerToAgoraStableSwapStorage().swapStorage.reserve0;
    }

    function reserve1() public view returns (uint256) {
        return _getPointerToAgoraStableSwapStorage().swapStorage.reserve1;
    }

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
            _amounts[1] = _getAmount0Out(_amountIn, _token0OverToken1Price, _storage.token0PurchaseFee);
        } else {
            _amounts[1] = _getAmount1Out(_amountIn, _token0OverToken1Price, _storage.token1PurchaseFee);
        }
    }

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
            _amounts[0] = _getAmount0In(_amountOut, _token0OverToken1Price, _storage.token0PurchaseFee);
        } else {
            _amounts[0] = _getAmount1In(_amountOut, _token0OverToken1Price, _storage.token1PurchaseFee);
        }
    }
}
