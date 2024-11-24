// SPDX-License-Identifier: ISC
pragma solidity ^0.8.28;

import { AgoraStableSwapAccessControl } from "./AgoraStableSwapAccessControl.sol";

import { IUniswapV2Callee } from "../interfaces/IUniswapV2Callee.sol";

import { AgoraCompoundingOracle } from "./AgoraStableSwapCompoundingOracle.sol";
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

contract AgoraStableSwapPairCore is
    AgoraStableSwapPairStorage,
    AgoraStableSwapAccessControl,
    AgoraCompoundingOracle,
    Initializable
{
    using SafeERC20 for IERC20;

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

    function _getAmountsOut(
        uint256 _amountIn,
        address[] memory _path,
        address _token0,
        address _token1,
        uint256 _token0PurchaseFee,
        uint256 _token1PurchaseFee,
        uint256 _token0OverToken1Price
    ) internal pure returns (uint256[] memory _amounts) {
        // enforce parameter sizes
        if (_path.length != 2) revert InvalidPath();
        // make sure token0 exists in the path
        if (_token0 != _path[0] || _token1 != _path[1]) revert InvalidPath();
        // make sure token1 exists in the path
        if (_token1 != _path[0] || _token0 != _path[1]) revert InvalidPath();

        _amounts = new uint256[](2);
        _amounts[0] = _amountIn;

        // path[1] represents our tokenOut
        if (_path[1] == _token0) _amounts[1] = _getAmount0Out(_amountIn, _token0OverToken1Price, _token0PurchaseFee);
        else _amounts[1] = _getAmount1Out(_amountIn, _token0OverToken1Price, _token1PurchaseFee);
    }

    function _getAmountsIn(
        uint256 _amountOut,
        address[] memory _path,
        address _token0,
        address _token1,
        uint256 _token0PurchaseFee,
        uint256 _token1PurchaseFee,
        uint256 _token0OverToken1Price
    ) internal pure returns (uint256[] memory _amounts) {
        // enforce parameter sizes
        if (_path.length != 2) revert InvalidPath();
        // make sure token0 exists in the path
        if (_token0 != _path[0] || _token1 != _path[1]) revert InvalidPath();
        // make sure token1 exists in the path
        if (_token1 != _path[0] || _token0 != _path[1]) revert InvalidPath();

        _amounts = new uint256[](2);
        // set the amountOut
        _amounts[1] = _amountOut;

        // path[0] represents our tokenIn
        if (_path[0] == _token0) _amounts[0] = _getAmount0In(_amountOut, _token0OverToken1Price, _token0PurchaseFee);
        else _amounts[0] = _getAmount1In(_amountOut, _token0OverToken1Price, _token1PurchaseFee);
    }

    //==============================================================================
    // External Stateful Functions
    //==============================================================================

    function swap(uint256 _amount0Out, uint256 _amount1Out, address _to, bytes memory _data) public nonreentrant {
        _requireSenderIsRole(APPROVED_SWAPPER);
        // Force one amountOut to be 0
        if (_amount0Out != 0 && _amount1Out != 0) revert("Invalid Swap Amounts");

        AgoraStableSwapStorage memory _storage = _getPointerToAgoraStableSwapStorage();

        // Cache information about the pair for gas savings
        address _token0 = _storage.token0;
        address _token1 = _storage.token1;
        uint256 _reserve0 = _storage.reserve0;
        uint256 _reserve1 = _storage.reserve1;
        uint256 _price = getPrice();

        // Check for proper liquidity available
        // TODO: look into what happens if the reserve is 0 and we want to deposit into that side of the pool.
        if (_amount0Out >= _reserve0 || _amount1Out >= _reserve1) revert("Insufficient Liquidity");

        // Send the tokens (you can only send 1)
        if (_amount0Out > 0) IERC20(_token0).safeTransfer(_to, _amount0Out);
        else IERC20(_token1).safeTransfer(_to, _amount1Out);
        // Execute the callback
        if (_data.length > 0) {
            IUniswapV2Callee(_to).uniswapV2Call({
                sender: msg.sender,
                amount0: _amount0Out,
                amount1: _amount1Out,
                data: _data
            });
        }
        // Take snapshot of balances
        uint256 _finalToken0Balance = IERC20(_token0).balanceOf(address(this));
        uint256 _finalToken1Balance = IERC20(_token1).balanceOf(address(this));

        // Calculate how many tokens were transferred
        uint256 _token0In = _finalToken0Balance > _reserve0 ? _finalToken0Balance - _reserve0 : 0;
        uint256 _token1In = _finalToken1Balance > _reserve1 ? _finalToken1Balance - _reserve1 : 0;

        // Check we received some tokens
        if (_token0In == 0 && _token1In == 0) revert("No Tokens Received");

        // Check that we received the correct amount of tokens
        if (_amount0Out > 0) {
            // we are sending token0 out, receiving token1 In
            uint256 _expectedAmount0Out = _getAmount0Out(_token1In, _price, _storage.token0PurchaseFee);
            if (_expectedAmount0Out > _reserve0 - _finalToken0Balance) revert("Invalid Swap");
        } else {
            // we are sending token1 out, receiving token0 in
            uint256 _expectedAmount1Out = _getAmount1Out(_token0In, _price, _storage.token1PurchaseFee);
            if (_expectedAmount1Out > _reserve1 - _finalToken1Balance) revert("Invalid Swap");
        }

        // Update reserves
        _sync(_finalToken0Balance, _finalToken1Balance);
    }

    function swapExactTokensForTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path,
        address _to,
        uint256 _deadline
    ) external nonreentrant {
        // CHECKS: block.timestamp must be less than deadline
        if (_deadline < block.timestamp) revert("Deadline Passed");

        AgoraStableSwapStorage memory _storage = _getPointerToAgoraStableSwapStorage();
        uint256 _token0OverToken1Price = getPrice();

        uint256[] memory _amounts = _getAmountsOut({
            _amountIn: _amountIn,
            _path: _path,
            _token0: _storage.token0,
            _token1: _storage.token1,
            _token0PurchaseFee: _storage.token0PurchaseFee,
            _token1PurchaseFee: _storage.token1PurchaseFee,
            _token0OverToken1Price: _token0OverToken1Price
        });
        // CHECKS: amountOut must not be smaller than the amountOutMin
        if (_amounts[1] < _amountOutMin) revert("Insufficient Output Amount");

        // EFFECTS: transfer tokens from msg.sender to this contract
        IERC20(_path[0]).safeTransferFrom(msg.sender, address(this), _amountIn);

        // EFFECTS: swap tokens
        swap(_amounts[0], _amounts[1], _to, new bytes(0));
    }

    function swapTokensForExactTokens(
        uint256 _amountOut,
        uint256 _amountInMax,
        address[] memory _path,
        address _to,
        uint256 _deadline
    ) external nonreentrant {
        // Checks: block.timestamp must be less than deadline
        if (_deadline < block.timestamp) revert("Deadline Passed");

        AgoraStableSwapStorage memory _storage = _getPointerToAgoraStableSwapStorage();
        uint256 _token0OverToken1Price = getPrice();

        uint256[] memory _amounts = _getAmountsIn({
            _amountOut: _amountOut,
            _path: _path,
            _token0: _storage.token0,
            _token1: _storage.token1,
            _token0PurchaseFee: _storage.token0PurchaseFee,
            _token1PurchaseFee: _storage.token1PurchaseFee,
            _token0OverToken1Price: _token0OverToken1Price
        });
        // CHECKS: amountInMax must be larger or equal to than the amountIn
        if (_amounts[0] > _amountInMax) revert("Amount In Max Exceeded");

        // EFFECTS: transfer tokens from msg.sender to this contract
        IERC20(_path[1]).safeTransferFrom(msg.sender, address(this), _amountInMax);

        // EFFECTS: swap tokens
        swap(_amounts[0], _amounts[1], _to, new bytes(0));
    }

    function sync() external {
        AgoraStableSwapStorage memory _storage = _getPointerToAgoraStableSwapStorage();
        _sync(IERC20(_storage.token0).balanceOf(address(this)), IERC20(_storage.token1).balanceOf(address(this)));
    }

    function _sync(uint256 _token0balance, uint256 _token1Balance) internal {
        _getPointerToAgoraStableSwapStorage().reserve0 = _token0balance;
        _getPointerToAgoraStableSwapStorage().reserve1 = _token1Balance;
    }

    //==============================================================================
    // Privileged Configuration Functions
    //==============================================================================

    event SetTokenReceiver(address indexed tokenReceiver);

    function setTokenReceiver(address _tokenReceiver) public {
        // Checks: Only the admin can set the token receiver
        _requireIsRole({ _role: ADMIN_ROLE, _address: msg.sender });

        // Effects: Set the token receiver
        _getPointerToAgoraStableSwapStorage().tokenReceiverAddress = _tokenReceiver;

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

    event SetTokenPurchaseFee(address indexed token, uint256 tokenPurchaseFee);

    function setTokenPurchaseFee(address _token, uint256 _tokenPurchaseFee) public {
        // CHECKS: Only the fee setter can set the fee
        _requireIsRole({ _role: FEE_SETTER_ROLE, _address: msg.sender });

        // Effects: Set the token1to0Fee
        if (_token == _getPointerToAgoraStableSwapStorage().token0) {
            _getPointerToAgoraStableSwapStorage().token0PurchaseFee = _tokenPurchaseFee;
        } else {
            _getPointerToAgoraStableSwapStorage().token1PurchaseFee = _tokenPurchaseFee;
        }

        // emit event
        emit SetTokenPurchaseFee({ token: _token, tokenPurchaseFee: _tokenPurchaseFee });
    }

    event RemoveTokens(address indexed tokenAddress, uint256 amount);

    function removeTokens(address _tokenAddress, uint256 _amount) external {
        // Checks: Only the token remover can remove tokens
        _requireIsRole({ _role: TOKEN_REMOVER_ROLE, _address: msg.sender });

        AgoraStableSwapStorage memory _storage = _getPointerToAgoraStableSwapStorage();

        if (_tokenAddress != _storage.token0 && _tokenAddress != _storage.token1) {
            revert InvalidTokenAddress({ token: _tokenAddress });
        }

        IERC20(_tokenAddress).safeTransfer(_storage.tokenReceiverAddress, _amount);

        // Update reserves
        if (_tokenAddress == _storage.token0) _getPointerToAgoraStableSwapStorage().reserve0 -= _amount;
        else _getPointerToAgoraStableSwapStorage().reserve1 -= _amount;

        // emit event
        emit RemoveTokens({ tokenAddress: _tokenAddress, amount: _amount });
    }

    event AddTokens(address indexed tokenAddress, address from, uint256 amount);

    function addTokens(address _tokenAddress, uint256 _amount) external {
        AgoraStableSwapStorage memory _storage = _getPointerToAgoraStableSwapStorage();

        if (_tokenAddress != _storage.token0 && _tokenAddress != _storage.token1) {
            revert InvalidTokenAddress({ token: _tokenAddress });
        }
        IERC20(_tokenAddress).safeTransferFrom(msg.sender, address(this), _amount);

        // Update reserves
        if (_tokenAddress == _storage.token0) _getPointerToAgoraStableSwapStorage().reserve0 += _amount;
        else _getPointerToAgoraStableSwapStorage().reserve1 += _amount;

        // emit event
        emit AddTokens({ tokenAddress: _tokenAddress, from: msg.sender, amount: _amount });
    }

    event SetPaused(bool isPaused);

    function setPaused(bool _isPaused) public {
        // Checks: Only the pauser can pause the pair
        _requireIsRole({ _role: PAUSER_ROLE, _address: msg.sender });

        // Effects: Set the isPaused state
        _getPointerToAgoraStableSwapStorage().isPaused = _isPaused;

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
    error InvalidSwap();
}
