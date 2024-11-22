// SPDX-License-Identifier: ISC
pragma solidity ^0.8.28;

import { AgoraStableSwapAccessControl } from "./AgoraStableSwapAccessControl.sol";

import { IUniswapV2Callee } from "../interfaces/IUniswapV2Callee.sol";

import { AgoraCompoundingOracle } from "./AgoraStableSwapCompoundingOracle.sol";

import { AgoraStableSwapPairCore } from "./AgoraStableSwapPairCore.sol";
import { AgoraStableSwapPairStorage } from "./AgoraStableSwapPairStorage.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

struct InitializeParams {
    address token0;
    address token1;
    uint256 token0PurchaseFee;
    uint256 token1PurchaseFee;
    address oracleAddress;
    address initialFeeSetter;
    address initialTokenReceiver;
}

contract AgoraStableSwapPair is AgoraStableSwapPairCore {
    using SafeERC20 for IERC20;

    // struct AgoraStableSwapStorage {
    //     address token0;
    //     address token1;
    //     uint256 token0PurchaseFee; // 18 decimals
    //     uint256 token1PurchaseFee; // 18 decimals
    //     address oracleAddress;
    //     uint256 token0OverToken1Price; // given as token1's price in token0
    //     uint256 reserve0;
    //     uint256 reserve1;
    //     uint256 lastBlock;
    //     bool isPaused;
    // }

    function token0() public view returns (address) {
        return _getPointerToAgoraStableSwapStorage().token0;
    }

    function token1() public view returns (address) {
        return _getPointerToAgoraStableSwapStorage().token1;
    }

    function token0PurchaseFee() public view returns (uint256) {
        return _getPointerToAgoraStableSwapStorage().token0PurchaseFee;
    }

    function token1PurchaseFee() public view returns (uint256) {
        return _getPointerToAgoraStableSwapStorage().token1PurchaseFee;
    }

    function oracleAddress() public view returns (address) {
        return _getPointerToAgoraStableSwapStorage().oracleAddress;
    }

    function isPaused() public view returns (bool) {
        return _getPointerToAgoraStableSwapStorage().isPaused;
    }

    function token0OverToken1Price() public view returns (uint256) {
        return _getPointerToAgoraStableSwapStorage().token0OverToken1Price;
    }

    function reserve0() public view returns (uint256) {
        return _getPointerToAgoraStableSwapStorage().reserve0;
    }

    function reserve1() public view returns (uint256) {
        return _getPointerToAgoraStableSwapStorage().reserve1;
    }

    function lastBlock() public view returns (uint256) {
        return _getPointerToAgoraStableSwapStorage().lastBlock;
    }

    //==============================================================================
    // Constructor & Initalization Functions
    //==============================================================================

    constructor() {
        _disableInitializers();
    }

    function initialize(InitializeParams memory _params) public initializer {
        // Set the token0 and token1
        _getPointerToAgoraStableSwapStorage().token0 = _params.token0;
        _getPointerToAgoraStableSwapStorage().token1 = _params.token1;

        // Set the token0to1Fee and token1to0Fee
        _getPointerToAgoraStableSwapStorage().token0PurchaseFee = _params.token0PurchaseFee;
        _getPointerToAgoraStableSwapStorage().token1PurchaseFee = _params.token1PurchaseFee;

        // Set the oracle address
        _getPointerToAgoraStableSwapStorage().oracleAddress = _params.oracleAddress;

        // Set the fee setter
        _setRoleMembership({ _role: FEE_SETTER_ROLE, _address: _params.initialFeeSetter, _insert: true });
        emit RoleAssigned({ role: FEE_SETTER_ROLE, address_: _params.initialFeeSetter });
    }

    function getAmountsOut(
        address _empty,
        uint256 _amountIn,
        address[] memory _path
    ) public view returns (uint256[] memory _amounts) {
        AgoraStableSwapStorage memory _storage = _getPointerToAgoraStableSwapStorage();
        uint256 _token0OverToken1Price = getPrice();
        return
            _getAmountsOut({
                _amountIn: _amountIn,
                _path: _path,
                _token0: _storage.token0,
                _token1: _storage.token1,
                _token0PurchaseFee: _storage.token0PurchaseFee,
                _token1PurchaseFee: _storage.token1PurchaseFee,
                _token0OverToken1Price: _token0OverToken1Price
            });
    }

    function getAmountsIn(
        address _empty,
        uint256 _amountOut,
        address[] memory _path
    ) public view returns (uint256[] memory _amounts) {
        AgoraStableSwapStorage memory _storage = _getPointerToAgoraStableSwapStorage();
        uint256 _token0OverToken1Price = getPrice();

        return
            _getAmountsIn({
                _amountOut: _amountOut,
                _path: _path,
                _token0: _storage.token0,
                _token1: _storage.token1,
                _token0PurchaseFee: _storage.token0PurchaseFee,
                _token1PurchaseFee: _storage.token1PurchaseFee,
                _token0OverToken1Price: _token0OverToken1Price
            });
    }
}
