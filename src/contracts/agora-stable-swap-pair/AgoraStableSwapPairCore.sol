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

/// @notice The ```InitializeParams``` struct is used to initialize the AgoraStableSwapPair
/// @param token0 The address of the first token in the pair
/// @param token1 The address of the second token in the pair
/// @param token0PurchaseFee The purchase fee for the first token in the pair
/// @param token1PurchaseFee The purchase fee for the second token in the pair
/// @param initialFeeSetter The address of the initial fee setter
/// @param initialTokenReceiver The address of the initial token receiver
/// @param initialAdminAddress The address of the initial admin
struct InitializeParams {
    address token0;
    address token1;
    uint256 token0PurchaseFee;
    uint256 token1PurchaseFee;
    address initialFeeSetter;
    address initialTokenReceiver;
    address initialAdminAddress;
}

/// @title AgoraStableSwapPairCore
/// @notice The AgoraStableSwapPairCore is a contract that manages the core logic for the AgoraStableSwapPair
/// @author Agora
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

    /// @notice The ```initialize``` function initializes the AgoraStableSwapPairCore contract
    /// @dev This function is called on the same transaction as the deployment of the contract
    /// @param _params The parameters for the initialization
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

    /// @notice The ```_requireValidPath``` function checks that the path is valid
    /// @param _path The path to check
    /// @param _token0 The address of the first token in the pair
    /// @param _token1 The address of the second token in the pair
    function _requireValidPath(address[] memory _path, address _token0, address _token1) internal pure {
        // Checks: path length is 2
        if (_path.length != 2) revert InvalidPath();

        // ! TODO: do we want to allow token1 to be on path[0]
        if (_path[0] == _token0 && _path[1] == _token1) return;
        else if (_path[0] == _token1 && _path[1] == _token0) return;
        revert InvalidPath();
    }

    /// @notice The ```getAmount0In``` function calculates the amount of input token0In required for a given amount token1Out
    /// @param _amountOut The amount of output token1
    /// @param _price The price of the pair expressed as token0 over token1
    /// @param _purchaseFeeToken0 The purchase fee for the token0
    /// @return _amountIn The amount of input token0
    function _getAmount0In(
        uint256 _amountOut,
        uint256 _price,
        uint256 _purchaseFeeToken0
    ) internal pure returns (uint256 _amountIn) {
        _amountIn = (_amountOut * _price) / ((PRECISION - _purchaseFeeToken0) * PRECISION);
    }

    /// @notice The ```_getAmount1In``` function calculates the amount of input token1In required for a given amount token0Out
    /// @param _amountOut The amount of output token0
    /// @param _price The price of the pair expressed as token0 over token1
    /// @param _purchaseFeeToken1 The purchase fee for the token1
    /// @return _amountIn The amount of input token1
    function _getAmount1In(
        uint256 _amountOut,
        uint256 _price,
        uint256 _purchaseFeeToken1
    ) internal pure returns (uint256 _amountIn) {
        _amountIn = _amountOut / ((PRECISION - _purchaseFeeToken1) * _price);
    }

    /// @notice The ```_getAmount0Out``` function calculates the amount of output token0Out returned from a given amount of input token1In
    /// @param _amountIn The amount of input token1
    /// @param _price The price of the pair expressed as token0 over token1
    /// @param _purchaseFeeToken0 The purchase fee for the token0
    /// @return _amountOut The amount of output token0
    function _getAmount0Out(
        uint256 _amountIn,
        uint256 _price,
        uint256 _purchaseFeeToken0
    ) internal pure returns (uint256 _amountOut) {
        _amountOut = (_amountIn * (PRECISION - _purchaseFeeToken0) * _price) / PRECISION;
    }

    /// @notice The ```_getAmount1Out``` function calculates the amount of output token1Out returned from a given amount of input token0In
    /// @param _amountIn The amount of input token0
    /// @param _price The price of the pair expressed as token0 over token1
    /// @param _purchaseFeeToken1 The purchase fee for the token1
    /// @return _amountOut The amount of output token1
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

    /// @notice The ```swap``` function swaps tokens in the pair
    /// @dev This function has a modifier that prevents reentrancy
    /// @param _amount0Out The amount of token0 to send out
    /// @param _amount1Out The amount of token1 to send out
    /// @param _to The address to send the tokens to
    /// @param _data The data to send to the callback
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
            uint256 _expectedAmount1In = _getAmount1In(_amount0Out, _token0OverToken1Price, _storage.token0PurchaseFee);
            if (_expectedAmount1In < _token1In) revert InsufficientInputAmount();
        } else {
            // we are sending token1 out, receiving token0 in
            uint256 _expectedAmount0In = _getAmount0In(_amount1Out, _token0OverToken1Price, _storage.token1PurchaseFee);
            if (_expectedAmount0In < _token0In) revert InsufficientInputAmount();
        }

        // Update reserves
        _sync(_finalToken0Balance, _finalToken1Balance);

        // ! TODO: is this event declared anywhere? overload?
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

    /// @notice The ```swapExactTokensForTokens``` function swaps an exact amount of input tokenIn for an amount of output tokenOut
    /// @param _amountIn The amount of input tokenIn
    /// @param _amountOutMin The minimum amount of output tokenOut
    /// @param _path The path of the tokens
    /// @param _to The address to send the tokens to
    /// @param _deadline The deadline for the swap
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

    /// @notice The ```swapTokensForExactTokens``` function swaps an amount of output tokenOut for an exact amount of input tokenIn
    /// @param _amountOut The amount of output tokenOut
    /// @param _amountInMax The maximum amount of input tokenIn
    /// @param _path The path of the tokens
    /// @param _to The address to send the tokens to
    /// @param _deadline The deadline for the swap
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

    /// @notice The ```sync``` function syncs the reserves of the pair
    /// @dev This function is used to sync the reserves of the pair
    function sync() external {
        SwapStorage memory _storage = _getPointerToAgoraStableSwapStorage().swapStorage;
        _sync(IERC20(_storage.token0).balanceOf(address(this)), IERC20(_storage.token1).balanceOf(address(this)));
    }

    /// @notice The ```_sync``` function syncs the reserves of the pair
    /// @param _token0balance The balance of token0
    /// @param _token1Balance The balance of token1
    function _sync(uint256 _token0balance, uint256 _token1Balance) internal {
        _getPointerToAgoraStableSwapStorage().swapStorage.reserve0 = _token0balance.toUint112();
        _getPointerToAgoraStableSwapStorage().swapStorage.reserve1 = _token1Balance.toUint112();
    }

    //==============================================================================
    // Privileged Configuration Functions
    //==============================================================================

    /// @notice The ```SetTokenReceiver``` event is emitted when the token receiver is set
    /// @param tokenReceiver The address of the token receiver
    event SetTokenReceiver(address indexed tokenReceiver);

    /// @notice The ```setTokenReceiver``` function sets the token receiver
    /// @param _tokenReceiver The address of the token receiver
    function setTokenReceiver(address _tokenReceiver) public {
        // Checks: Only the admin can set the token receiver
        _requireIsRole({ _role: ADMIN_ROLE, _address: msg.sender });

        // Effects: Set the token receiver
        _getPointerToAgoraStableSwapStorage().config.tokenReceiverAddress = _tokenReceiver;

        // emit event
        emit SetTokenReceiver({ tokenReceiver: _tokenReceiver });
    }

    /// @notice The ```SetApprovedSwapper``` event is emitted when the approved swapper is set
    /// @param approvedSwapper The address of the approved swapper
    /// @param isApproved The boolean value indicating whether the swapper is approved
    event SetApprovedSwapper(address indexed approvedSwapper, bool isApproved);

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

    /// @notice The ```SetFeeBounds``` event is emitted when the fee bounds are set
    /// @param minToken0PurchaseFee The minimum purchase fee for token0
    /// @param maxToken0PurchaseFee The maximum purchase fee for token0
    /// @param minToken1PurchaseFee The minimum purchase fee for token1
    /// @param maxToken1PurchaseFee The maximum purchase fee for token1
    event SetFeeBounds(
        uint256 minToken0PurchaseFee,
        uint256 maxToken0PurchaseFee,
        uint256 minToken1PurchaseFee,
        uint256 maxToken1PurchaseFee
    );

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

    /// @notice The ```SetTokenPurchaseFee``` event is emitted when the token purchase fee is set
    /// @param token The address of the token
    /// @param tokenPurchaseFee The purchase fee for the token
    event SetTokenPurchaseFee(address indexed token, uint256 tokenPurchaseFee);

    /// @notice The ```setTokenPurchaseFee``` function sets the token purchase fee
    /// @param _token The address of the token
    /// @param _tokenPurchaseFee The purchase fee for the token
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

    /// @notice The ```RemoveTokens``` event is emitted when tokens are removed
    /// @param tokenAddress The address of the token
    /// @param amount The amount of tokens to remove
    event RemoveTokens(address indexed tokenAddress, uint256 amount);

    /// @notice The ```removeTokens``` function removes tokens from the pair
    /// @param _tokenAddress The address of the token
    /// @param _amount The amount of tokens to remove
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

    /// @notice The ```AddTokens``` event is emitted when tokens are added
    /// @param tokenAddress The address of the token
    /// @param from The address of the sender
    /// @param amount The amount of tokens to add
    event AddTokens(address indexed tokenAddress, address from, uint256 amount);

    /// @notice The ```addTokens``` function adds tokens to the pair
    /// @param _tokenAddress The address of the token
    /// @param _amount The amount of tokens to add
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

    /// @notice The ```SetPaused``` event is emitted when the pair is paused
    /// @param isPaused The boolean value indicating whether the pair is paused
    event SetPaused(bool isPaused);

    /// @notice The ```setPaused``` function sets the paused state of the pair
    /// @param _setPaused The boolean value indicating whether the pair is paused
    function setPaused(bool _setPaused) public {
        // Checks: Only the pauser can pause the pair
        _requireIsRole({ _role: PAUSER_ROLE, _address: msg.sender });

        // Effects: Set the isPaused state
        _getPointerToAgoraStableSwapStorage().swapStorage.isPaused = _setPaused;

        // emit event
        emit SetPaused({ isPaused: _setPaused });
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
    error AmountOutInsufficient(uint256 provided, uint256 minimum);

    /// @notice Emitted when the amountInMax is less than the amountIn
    /// @notice Emitted when the reserve is insufficient
    error InsufficientLiquidity();

    /// @notice Emitted when the token purchase fee is invalid
    error InvalidTokenPurchaseFee(address token);
}
