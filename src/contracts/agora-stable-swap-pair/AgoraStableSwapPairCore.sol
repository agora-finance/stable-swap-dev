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
// ==================== AgoraStableSwapPairCore =======================
// ====================================================================

import { AgoraStableSwapAccessControl } from "./AgoraStableSwapAccessControl.sol";

import { IUniswapV2Callee } from "../interfaces/IUniswapV2Callee.sol";

import { AgoraCompoundingOracle } from "./AgoraCompoundingOracle.sol";
import { AgoraStableSwapPairStorage } from "./AgoraStableSwapPairStorage.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

struct InitializeParams {
    address token0;
    address token1;
    uint256 token0PurchaseFee;
    uint256 token1PurchaseFee;
    address initialFeeSetter;
    address initialTokenReceiver;
    address initialAdminAddress;
}

contract AgoraStableSwapPairCore is
    AgoraStableSwapPairStorage,
    AgoraStableSwapAccessControl,
    AgoraCompoundingOracle,
    Initializable
{
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    // struct AgoraStableSwapStorage {
    //     address token0;
    //     address token1;
    //     uint256 token0PurchaseFee; // 18 decimals
    //     uint256 minToken0PurchaseFee; // 18 decimals
    //     uint256 maxToken0PurchaseFee; // 18 decimals
    //     uint256 token1PurchaseFee; // 18 decimals
    //     uint256 minToken1PurchaseFee; // 18 decimals
    //     uint256 maxToken1PurchaseFee; // 18 decimals
    //     address oracleAddress;
    //     uint256 token0OverToken1Price; // given as token1's price in token0
    //     uint256 reserve0;
    //     uint256 reserve1;
    //     uint256 lastBlock;
    //     bool isPaused;
    //     address tokenReceiverAddress;
    // }

    //==============================================================================
    // Constructor & Initalization Functions
    //==============================================================================

    constructor() {
        _disableInitializers();
    }

    function initialize(InitializeParams memory _params) public initializer {
        // Initialize the access control and oracle
        _initializeAgoraStableSwapAccessControl({ _initialAdminAddress: _params.initialAdminAddress });
        _initializeAgoraCompoundingOracle();

        // Set the token0 and token1
        _getPointerToAgoraStableSwapStorage().swapStorage.token0 = _params.token0;
        _getPointerToAgoraStableSwapStorage().swapStorage.token1 = _params.token1;

        // Set the token0to1Fee and token1to0Fee
        _getPointerToAgoraStableSwapStorage().swapStorage.token0PurchaseFee = _params.token0PurchaseFee.toUint16();
        emit SetTokenPurchaseFee({ token: _params.token0, tokenPurchaseFee: _params.token0PurchaseFee });

        _getPointerToAgoraStableSwapStorage().swapStorage.token1PurchaseFee = _params.token1PurchaseFee.toUint16();
        emit SetTokenPurchaseFee({ token: _params.token1, tokenPurchaseFee: _params.token1PurchaseFee });

        // Set the tokenReceiverAddress
        _getPointerToAgoraStableSwapStorage().config.tokenReceiverAddress = _params.initialTokenReceiver;
        emit SetTokenReceiver({ tokenReceiver: _params.initialTokenReceiver });
    }
    //==============================================================================
    // Modifiers
    //==============================================================================

    modifier nonreentrant() {
        assembly {
            if tload(AGORA_STABLE_SWAP_TRANSIENT_LOCK_SLOT) {
                revert(0, 0)
            }
            tstore(AGORA_STABLE_SWAP_TRANSIENT_LOCK_SLOT, 1)
        }
        _;
        // Unlocks the guard, making the pattern composable.
        // After the function exits, it can be called again, even in the same transaction.
        assembly {
            tstore(AGORA_STABLE_SWAP_TRANSIENT_LOCK_SLOT, 0)
        }
    }

    //==============================================================================
    // Internal Helper Functions
    //==============================================================================

    function _requireValidPath(address[] memory _path, address _token0, address _token1) internal pure {
        // Checks: path length is 2
        if (_path.length != 2) revert InvalidPath();

        // Checks: path must contain token0 and token1
        if (_path[0] == _token0) {
            if (_path[1] != _token1) {
                revert InvalidPath();
            } else if (_path[0] == _token1) {
                if (_path[1] != _token0) revert InvalidPath();
                else revert InvalidPath();
            }
        }
    }

    function _getAmount0In(
        uint256 _amountOut,
        uint256 _price,
        uint256 _purchaseFeeToken0
    ) internal pure returns (uint256 _amountIn) {
        _amountIn = (_amountOut * _price) / ((PRECISION - _purchaseFeeToken0) * PRECISION);
    }

    function _getAmount1In(
        uint256 _amountOut,
        uint256 _price,
        uint256 _purchaseFeeToken1
    ) internal pure returns (uint256 _amountIn) {
        _amountIn = _amountOut / ((PRECISION - _purchaseFeeToken1) * _price);
    }

    function _getAmount0Out(
        uint256 _amountIn,
        uint256 _price,
        uint256 _purchaseFeeToken0
    ) internal pure returns (uint256 _amountOut) {
        _amountOut = (_amountIn * (PRECISION - _purchaseFeeToken0) * _price) / PRECISION;
    }

    function _getAmount1Out(
        uint256 _amountIn,
        uint256 _price,
        uint256 _purchaseFeeToken1
    ) internal pure returns (uint256 _amountOut) {
        _amountOut = (_amountIn * (PRECISION - _purchaseFeeToken1)) / _price;
    }

    //==============================================================================
    // External Stateful Functions
    //==============================================================================

    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    function swap(uint256 _amount0Out, uint256 _amount1Out, address _to, bytes memory _data) public nonreentrant {
        _requireSenderIsRole({ _role: APPROVED_SWAPPER });

        // Checks: input sanitation, force one amountOut to be 0, and the other to be > 0
        if ((_amount0Out != 0 && _amount1Out != 0) || (_amount0Out == 0 && _amount1Out == 0)) {
            revert InvalidSwapAmounts();
        }

        // Cache information about the pair for gas savings
        SwapStorage memory _storage = _getPointerToAgoraStableSwapStorage().swapStorage;
        uint256 _token0OverToken1Price = getPrice();

        // Checks: proper liquidity available, NOTE: we allow emptying the pair
        if (_amount0Out > _storage.reserve0 || _amount1Out > _storage.reserve1) revert InsufficientLiquidity();

        // Send the tokens (you can only send 1)
        if (_amount0Out > 0) IERC20(_storage.token0).safeTransfer(_to, _amount0Out);
        else IERC20(_storage.token1).safeTransfer(_to, _amount1Out);

        // Execute the callback (if relevant)
        if (_data.length > 0) {
            IUniswapV2Callee(_to).uniswapV2Call({
                sender: msg.sender,
                amount0: _amount0Out,
                amount1: _amount1Out,
                data: _data
            });
        }

        // Take snapshot of balances
        uint256 _finalToken0Balance = IERC20(_storage.token0).balanceOf({ account: address(this) });
        uint256 _finalToken1Balance = IERC20(_storage.token1).balanceOf({ account: address(this) });

        // Calculate how many tokens were transferred
        uint256 _token0In = _finalToken0Balance > _storage.reserve0 - _amount0Out
            ? _finalToken0Balance - (_storage.reserve0 - _amount0Out)
            : 0;
        uint256 _token1In = _finalToken1Balance > _storage.reserve1 - _amount1Out
            ? _finalToken1Balance - (_storage.reserve1 - _amount1Out)
            : 0;

        // Checks:: Final invariant, ensure that we received the correct amount of tokens
        if (_amount0Out > 0) {
            // we are sending token0 out, receiving token1 In
            uint256 _expectedAmount1In = _getAmount1In(_amount1Out, _token0OverToken1Price, _storage.token0PurchaseFee);
            if (_expectedAmount1In < _token1In) revert InsufficientInputAmount();
        } else {
            // we are sending token1 out, receiving token0 in
            uint256 _expectedAmount0In = _getAmount0In(_amount1Out, _token0OverToken1Price, _storage.token1PurchaseFee);
            if (_expectedAmount0In < _token0In) revert InsufficientInputAmount();
        }

        // Update reserves
        _sync(_finalToken0Balance, _finalToken1Balance);

        // emit event
        emit Swap({
            sender: msg.sender,
            amount0In: _token0In,
            amount1In: _token1In,
            amount0Out: _amount0Out,
            amount1Out: _amount1Out,
            to: _to
        });
    }

    function swapExactTokensForTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path,
        address _to,
        uint256 _deadline
    ) external nonreentrant {
        // Checks: block.timestamp must be less than deadline
        if (_deadline < block.timestamp) revert DeadlinePassed();

        SwapStorage memory _storage = _getPointerToAgoraStableSwapStorage().swapStorage;
        uint256 _token0OverToken1Price = getPrice();

        // Checks: path length is 2 && path must contain token0 and token1 only
        _requireValidPath({ _path: _path, _token0: _storage.token0, _token1: _storage.token1 });

        // Calculations: determine amounts based on path

        uint256 _amountOut = _path[1] == _storage.token0
            ? _getAmount0Out(_amountIn, _token0OverToken1Price, _storage.token0PurchaseFee)
            : _getAmount1Out(_amountIn, _token0OverToken1Price, _storage.token1PurchaseFee);

        // Checks: amountOut must not be smaller than the amountOutMin
        if (_amountOut < _amountOutMin) revert AmountOutInsufficient();

        // Interactions: transfer tokens from msg.sender to this contract
        IERC20(_path[0]).safeTransferFrom({ from: msg.sender, to: address(this), value: _amountIn });

        // Effects: swap tokens
        if (_path[1] == _storage.token0) {
            swap({ _amount0Out: _amountOut, _amount1Out: 0, _to: _to, _data: new bytes(0) });
        } else {
            swap({ _amount0Out: 0, _amount1Out: _amountOut, _to: _to, _data: new bytes(0) });
        }
    }

    function swapTokensForExactTokens(
        uint256 _amountOut,
        uint256 _amountInMax,
        address[] memory _path,
        address _to,
        uint256 _deadline
    ) external nonreentrant {
        // Checks: block.timestamp must be less than deadline
        if (_deadline < block.timestamp) revert DeadlinePassed();

        SwapStorage memory _storage = _getPointerToAgoraStableSwapStorage().swapStorage;
        uint256 _token0OverToken1Price = getPrice();

        // Checks: path length is 2 && path must contain token0 and token1 only
        _requireValidPath({ _path: _path, _token0: _storage.token0, _token1: _storage.token1 });

        // Calculations: determine amounts based on path
        uint256 _amountIn = _path[0] == _storage.token0
            ? _getAmount0In(_amountOut, _token0OverToken1Price, _storage.token0PurchaseFee)
            : _getAmount1In(_amountOut, _token0OverToken1Price, _storage.token1PurchaseFee);
        // Checks: amountInMax must be larger or equal to than the amountIn
        if (_amountIn > _amountInMax) revert AmountInMaxExceeded();

        // Interactions: transfer tokens from msg.sender to this contract
        IERC20(_path[1]).safeTransferFrom(msg.sender, address(this), _amountIn);

        // Effects: swap tokens
        if (_path[1] == _storage.token0) {
            swap({ _amount0Out: _amountOut, _amount1Out: 0, _to: _to, _data: new bytes(0) });
        } else {
            swap({ _amount0Out: 0, _amount1Out: _amountOut, _to: _to, _data: new bytes(0) });
        }
    }

    function sync() external {
        SwapStorage memory _storage = _getPointerToAgoraStableSwapStorage().swapStorage;
        _sync(IERC20(_storage.token0).balanceOf(address(this)), IERC20(_storage.token1).balanceOf(address(this)));
    }

    function _sync(uint256 _token0balance, uint256 _token1Balance) internal {
        _getPointerToAgoraStableSwapStorage().swapStorage.reserve0 = _token0balance.toUint112();
        _getPointerToAgoraStableSwapStorage().swapStorage.reserve1 = _token1Balance.toUint112();
    }

    //==============================================================================
    // Privileged Configuration Functions
    //==============================================================================

    event SetTokenReceiver(address indexed tokenReceiver);

    function setTokenReceiver(address _tokenReceiver) public {
        // Checks: Only the admin can set the token receiver
        _requireIsRole({ _role: ADMIN_ROLE, _address: msg.sender });

        // Effects: Set the token receiver
        _getPointerToAgoraStableSwapStorage().config.tokenReceiverAddress = _tokenReceiver;

        // emit event
        emit SetTokenReceiver({ tokenReceiver: _tokenReceiver });
    }

    event SetApprovedSwapper(address indexed approvedSwapper, bool isApproved);

    function setApprovedSwapper(address _approvedSwapper, bool _isApproved) public {
        // Checks: Only the whitelister can set the approved swapper
        _requireIsRole({ _role: WHITELISTER_ROLE, _address: msg.sender });

        // Effects: Set the isApproved state
        _assignRole({ _role: APPROVED_SWAPPER, _newAddress: _approvedSwapper, _addRole: _isApproved });

        // emit event
        emit SetApprovedSwapper({ approvedSwapper: _approvedSwapper, isApproved: _isApproved });
    }

    event SetFeeBounds(
        uint256 minToken0PurchaseFee,
        uint256 maxToken0PurchaseFee,
        uint256 minToken1PurchaseFee,
        uint256 maxToken1PurchaseFee
    );

    function setFeeBounds(
        uint256 minToken0PurchaseFee,
        uint256 maxToken0PurchaseFee,
        uint256 minToken1PurchaseFee,
        uint256 maxToken1PurchaseFee
    ) external {
        // Checks: Only the admin can set the fee bounds
        _requireSenderIsRole({ _role: ADMIN_ROLE });

        // Effects: Set the fee bounds
        _getPointerToAgoraStableSwapStorage().config.minToken0PurchaseFee = minToken0PurchaseFee;
        _getPointerToAgoraStableSwapStorage().config.maxToken0PurchaseFee = maxToken0PurchaseFee;
        _getPointerToAgoraStableSwapStorage().config.minToken1PurchaseFee = minToken1PurchaseFee;
        _getPointerToAgoraStableSwapStorage().config.maxToken1PurchaseFee = maxToken1PurchaseFee;

        emit SetFeeBounds({
            minToken0PurchaseFee: minToken0PurchaseFee,
            maxToken0PurchaseFee: maxToken0PurchaseFee,
            minToken1PurchaseFee: minToken1PurchaseFee,
            maxToken1PurchaseFee: maxToken1PurchaseFee
        });
    }

    event SetTokenPurchaseFee(address indexed token, uint256 tokenPurchaseFee);

    function setTokenPurchaseFee(address _token, uint256 _tokenPurchaseFee) public {
        // Checks: Only the fee setter can set the fee
        _requireIsRole({ _role: FEE_SETTER_ROLE, _address: msg.sender });

        // Effects: Set the token1to0Fee
        if (_token == _getPointerToAgoraStableSwapStorage().swapStorage.token0) {
            if (
                _tokenPurchaseFee < _getPointerToAgoraStableSwapStorage().config.minToken0PurchaseFee ||
                _tokenPurchaseFee > _getPointerToAgoraStableSwapStorage().config.maxToken0PurchaseFee
            ) revert InvalidTokenPurchaseFee({ token: _token });
            _getPointerToAgoraStableSwapStorage().swapStorage.token0PurchaseFee = _tokenPurchaseFee.toUint16();
        } else if (_token == _getPointerToAgoraStableSwapStorage().swapStorage.token1) {
            if (
                _tokenPurchaseFee < _getPointerToAgoraStableSwapStorage().config.minToken1PurchaseFee ||
                _tokenPurchaseFee > _getPointerToAgoraStableSwapStorage().config.maxToken1PurchaseFee
            ) revert InvalidTokenPurchaseFee({ token: _token });
            _getPointerToAgoraStableSwapStorage().swapStorage.token1PurchaseFee = _tokenPurchaseFee.toUint16();
        } else {
            revert InvalidTokenAddress({ token: _token });
        }

        // emit event
        emit SetTokenPurchaseFee({ token: _token, tokenPurchaseFee: _tokenPurchaseFee });
    }

    event RemoveTokens(address indexed tokenAddress, uint256 amount);

    function removeTokens(address _tokenAddress, uint256 _amount) external {
        // Checks: Only the token remover can remove tokens
        _requireIsRole({ _role: TOKEN_REMOVER_ROLE, _address: msg.sender });

        SwapStorage memory _swapStorage = _getPointerToAgoraStableSwapStorage().swapStorage;
        ConfigStorage memory _configStorage = _getPointerToAgoraStableSwapStorage().config;

        if (_tokenAddress != _swapStorage.token0 && _tokenAddress != _swapStorage.token1) {
            revert InvalidTokenAddress({ token: _tokenAddress });
        }

        IERC20(_tokenAddress).safeTransfer(_configStorage.tokenReceiverAddress, _amount);

        // Update reserves
        _sync({
            _token0balance: IERC20(_swapStorage.token0).balanceOf(address(this)),
            _token1Balance: IERC20(_swapStorage.token1).balanceOf(address(this))
        });

        // emit event
        emit RemoveTokens({ tokenAddress: _tokenAddress, amount: _amount });
    }

    event AddTokens(address indexed tokenAddress, address from, uint256 amount);

    function addTokens(address _tokenAddress, uint256 _amount) external {
        SwapStorage memory _storage = _getPointerToAgoraStableSwapStorage().swapStorage;

        if (_tokenAddress != _storage.token0 && _tokenAddress != _storage.token1) {
            revert InvalidTokenAddress({ token: _tokenAddress });
        }
        IERC20(_tokenAddress).safeTransferFrom(msg.sender, address(this), _amount);

        // Update reserves
        _sync({
            _token0balance: IERC20(_storage.token0).balanceOf(address(this)),
            _token1Balance: IERC20(_storage.token1).balanceOf(address(this))
        });

        // emit event
        emit AddTokens({ tokenAddress: _tokenAddress, from: msg.sender, amount: _amount });
    }

    event SetPaused(bool isPaused);

    function setPaused(bool _isPaused) public {
        // Checks: Only the pauser can pause the pair
        _requireIsRole({ _role: PAUSER_ROLE, _address: msg.sender });

        // Effects: Set the isPaused state
        _getPointerToAgoraStableSwapStorage().swapStorage.isPaused = _isPaused;

        // emit event
        emit SetPaused({ isPaused: _isPaused });
    }

    // ============================================================================================
    // Errors
    // ============================================================================================

    /// @notice Emitted when an invalid token is passed to a function
    /// @param token The address of the token that was invalid
    error InvalidTokenAddress(address token);

    /// @notice Emitted when an invalid path is passed to a function
    error InvalidPath();

    /// @notice Emitted when an invalid swap amount is returned from a function
    error InvalidAmount();

    /// @notice Emitted when both amounts cannot be non-zero
    error InvalidSwapAmounts();

    /// @notice Emitted when the deadline is passed
    error DeadlinePassed();

    /// @notice Emitted when the amountOut is less than the minimum amountOut
    error AmountOutInsufficient();

    /// @notice Emitted when the amountInMax is less than the amountIn
    error AmountInMaxExceeded();

    /// @notice Emitted when no tokens are received
    error InsufficientInputAmount();

    /// @notice Emitted when the reserve is insufficient
    error InsufficientLiquidity();

    /// @notice Emitted when the token purchase fee is invalid
    error InvalidTokenPurchaseFee(address token);
}
