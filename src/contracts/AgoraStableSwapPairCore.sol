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
import { ReentrancyGuardTransient } from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";

import { AgoraStableSwapAccessControl } from "./AgoraStableSwapAccessControl.sol";

import { IUniswapV2Callee } from "./interfaces/IUniswapV2Callee.sol";

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
contract AgoraStableSwapPairCore is AgoraStableSwapAccessControl, Initializable, ReentrancyGuardTransient {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    //==============================================================================
    // Storage Structs
    //==============================================================================
    struct ConfigStorage {
        uint256 minToken0PurchaseFee; // 18 decimals precision, max value 1
        uint256 maxToken0PurchaseFee; // 18 decimals precision, max value 1
        uint256 minToken1PurchaseFee; // 18 decimals precision, max value 1
        uint256 maxToken1PurchaseFee; // 18 decimals precision, max value 1
        address tokenReceiverAddress;
        uint256 minBasePrice;
        uint256 maxBasePrice;
        uint256 minAnnualizedInterestRate;
        uint256 maxAnnualizedInterestRate;
    }

    struct SwapStorage {
        bool isPaused;
        address token0;
        uint8 token0Decimals;
        address token1;
        uint8 token1Decimals;
        uint112 reserve0;
        uint112 reserve1;
        uint64 token0PurchaseFee; // 18 decimals precision, max value 1
        uint64 token1PurchaseFee; // 18 decimals precision, max value 1
        uint40 priceLastUpdated;
        uint64 perSecondInterestRate; // 18 decimals of precision
        uint256 basePrice; // 18 decimals of precision
    }

    /// @notice The AgoraStableSwapStorage struct is used to store the state of the AgoraStableSwapPair contract
    /// @param isPaused The boolean value indicating whether the pair is paused
    /// @param token0 The address of token0
    /// @param token1 The address of token1
    /// @param token0PurchaseFee The purchase fee for token0
    /// @param minToken0PurchaseFee The minimum purchase fee for token0
    /// @param maxToken0PurchaseFee The maximum purchase fee for token0
    /// @param token1PurchaseFee The purchase fee for token1
    /// @param minToken1PurchaseFee The minimum purchase fee for token1
    /// @param maxToken1PurchaseFee The maximum purchase fee for token1
    /// @param oracleAddress The address of the oracle
    /// @param reserve0 The reserve of token0
    /// @param reserve1 The reserve of token1
    /// @param lastBlock The last block number
    /// @param tokenReceiverAddress The address of the token receiver
    struct AgoraStableSwapStorage {
        SwapStorage swapStorage;
        ConfigStorage configStorage;
    }

    //==============================================================================
    // Erc 7201: UnstructuredNamespace Storage Functions
    //==============================================================================

    /// @notice The ```AGORA_STABLE_SWAP_STORAGE_SLOT``` is the storage slot for the AgoraStableSwapStorage struct
    /// @dev keccak256(abi.encode(uint256(keccak256("AgoraStableSwapPairStorage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant AGORA_STABLE_SWAP_STORAGE_SLOT =
        0x7bec511bd7f6687e2731c8fe683a8e6468bf371b3ebd503eee87dd5465b4a500;

    /// @notice The ```_getPointerToAgoraStableSwapStorage``` function returns a pointer to the AgoraStableSwapStorage struct
    /// @return $ A pointer to the AgoraStableSwapStorage struct
    function _getPointerToStorage() internal pure returns (AgoraStableSwapStorage storage $) {
        /// @solidity memory-safe-assembly
        assembly {
            $.slot := AGORA_STABLE_SWAP_STORAGE_SLOT
        }
    }

    /// @notice The ```AGORA_STABLE_SWAP_TRANSIENT_LOCK_SLOT``` is the storage slot for the re-entrancy lock
    /// @dev keccak256(abi.encode(uint256(keccak256("AgoraStableSwapStorage.TransientReentrancyLock")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant AGORA_STABLE_SWAP_TRANSIENT_LOCK_SLOT =
        0x1c912e2d5b9a8ca13ccf418e7dc8bfe55d8292938ebaef5b3166abbe45f04b00;

    uint256 public constant PRICE_PRECISION = 1e18;
    uint256 public constant FEE_PRECISION = 1e18;

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

        // Set oracle last updated & basePrice
        _getPointerToStorage().swapStorage.priceLastUpdated = block.timestamp.toUint40();
        _getPointerToStorage().swapStorage.basePrice = 1e18;
        emit ConfigureOraclePrice({ basePrice: 1e18, annualizedInterestRate: 0 });

        // Set the token0 and token1
        _getPointerToStorage().swapStorage.token0 = _params.token0;
        _getPointerToStorage().swapStorage.token1 = _params.token1;

        // Set the token0to1Fee and token1to0Fee
        _getPointerToStorage().swapStorage.token0PurchaseFee = _params.token0PurchaseFee.toUint64();
        _getPointerToStorage().swapStorage.token1PurchaseFee = _params.token1PurchaseFee.toUint64();
        emit SetTokenPurchaseFees({
            token0PurchaseFee: _params.token0PurchaseFee,
            token1PurchaseFee: _params.token1PurchaseFee
        });

        // Set the tokenReceiverAddress
        _getPointerToStorage().configStorage.tokenReceiverAddress = _params.initialTokenReceiver;
        emit SetTokenReceiver({ tokenReceiver: _params.initialTokenReceiver });
    }

    //==============================================================================
    // Internal Helper Functions
    //==============================================================================

    /// @notice The ```requireValidPath``` function checks that the path is valid
    /// @param _path The path to check
    /// @param _token0 The address of the first token in the pair
    /// @param _token1 The address of the second token in the pair
    function requireValidPath(address[] memory _path, address _token0, address _token1) public pure {
        // Checks: path length is 2
        if (_path.length != 2) revert InvalidPath();

        if (!(_path[0] == _token0 && _path[1] == _token1) || !(_path[0] == _token1 && _path[1] == _token0)) {
            revert InvalidPath();
        }
    }

    /// @notice The ```getAmount0In``` function calculates the amount of input token0In required for a given amount token1Out
    /// @param _amountOut The amount of output token1
    /// @param _token0OverToken1Price The price of the pair expressed as token0 over token1
    /// @param _token1PurchaseFee The purchase fee for the token0
    /// @return _amountIn The amount of input token0
    function getAmount0In(
        uint256 _amountOut,
        uint256 _token0OverToken1Price,
        uint256 _token1PurchaseFee
    ) public pure returns (uint256 _amountIn) {
        _amountIn =
            (_amountOut * _token0OverToken1Price * FEE_PRECISION) /
            ((FEE_PRECISION - _token1PurchaseFee) * PRICE_PRECISION);
        if (_amountIn * (FEE_PRECISION - _token1PurchaseFee) * PRICE_PRECISION < _amountOut * _token0OverToken1Price) {
            _amountIn += 1;
        }
    }

    /// @notice The ```getAmount1In``` function calculates the amount of input token1In required for a given amount token0Out
    /// @param _amountOut The amount of output token0
    /// @param _token0OverToken1Price The price of the pair expressed as token0 over token1
    /// @param _token0PurchaseFee The purchase fee for the token1
    /// @return _amountIn The amount of input token1
    function getAmount1In(
        uint256 _amountOut,
        uint256 _token0OverToken1Price,
        uint256 _token0PurchaseFee
    ) public pure returns (uint256 _amountIn) {
        _amountIn =
            (_amountOut * FEE_PRECISION * PRICE_PRECISION) /
            ((FEE_PRECISION - _token0PurchaseFee) * _token0OverToken1Price);
        if (_amountIn * (FEE_PRECISION - _token0PurchaseFee) * _token0OverToken1Price < _amountOut * PRICE_PRECISION) {
            _amountIn += 1;
        }
    }

    /// @notice The ```getAmount0Out``` function calculates the amount of output token0Out returned from a given amount of input token1In
    /// @param _amountIn The amount of input token1
    /// @param _token0OverToken1Price The price of the pair expressed as token0 over token1
    /// @param _token0PurchaseFee The purchase fee for the token0
    /// @return _amountOut The amount of output token0
    function getAmount0Out(
        uint256 _amountIn,
        uint256 _token0OverToken1Price,
        uint256 _token0PurchaseFee
    ) public pure returns (uint256 _amountOut) {
        _amountOut =
            (_amountIn * (FEE_PRECISION - _token0PurchaseFee) * _token0OverToken1Price) /
            (PRICE_PRECISION * FEE_PRECISION);
    }

    /// @notice The ```getAmount1Out``` function calculates the amount of output token1Out returned from a given amount of input token0In
    /// @param _amountIn The amount of input token0
    /// @param _token0OverToken1Price The price of the pair expressed as token0 over token1
    /// @param _token1PurchaseFee The purchase fee for the token1
    /// @return _amountOut The amount of output token1
    function getAmount1Out(
        uint256 _amountIn,
        uint256 _token0OverToken1Price,
        uint256 _token1PurchaseFee
    ) public pure returns (uint256 _amountOut) {
        _amountOut =
            (_amountIn * PRICE_PRECISION * (FEE_PRECISION - _token1PurchaseFee)) /
            (_token0OverToken1Price * FEE_PRECISION);
    }

    //==============================================================================
    // External Stateful Functions
    //==============================================================================

    /// @notice The ```swap``` function swaps tokens in the pair
    /// @dev This function has a modifier that prevents reentrancy
    /// @param _amount0Out The amount of token0 to send out
    /// @param _amount1Out The amount of token1 to send out
    /// @param _to The address to send the tokens to
    /// @param _data The data to send to the callback
    function swap(uint256 _amount0Out, uint256 _amount1Out, address _to, bytes memory _data) public nonReentrant {
        _requireSenderIsRole({ _role: APPROVED_SWAPPER });

        // Checks: input sanitation, force one amountOut to be 0, and the other to be > 0
        if ((_amount0Out != 0 && _amount1Out != 0) || (_amount0Out == 0 && _amount1Out == 0)) {
            revert InvalidSwapAmounts();
        }

        // Cache information about the pair for gas savings
        SwapStorage memory _storage = _getPointerToStorage().swapStorage;
        uint256 _token0OverToken1Price = getPrice();

        //Checks: ensure pair not paused
        if (_storage.isPaused) revert PairIsPaused();

        // Checks: proper liquidity available, NOTE: we allow emptying the pair
        if (_amount0Out > _storage.reserve0 || _amount1Out > _storage.reserve1) revert InsufficientLiquidity();

        // Send the tokens (you can only send 1)
        if (_amount0Out > 0) IERC20(_storage.token0).safeTransfer({ to: _to, value: _amount0Out });
        else IERC20(_storage.token1).safeTransfer({ to: _to, value: _amount1Out });

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
            uint256 _expectedAmount1In = getAmount1In(_amount0Out, _token0OverToken1Price, _storage.token0PurchaseFee);
            if (_expectedAmount1In < _token1In) revert InsufficientInputAmount();
        } else {
            // we are sending token1 out, receiving token0 in
            uint256 _expectedAmount0In = getAmount0In(_amount1Out, _token0OverToken1Price, _storage.token1PurchaseFee);
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
    ) external {
        // Checks: block.timestamp must be less than deadline
        if (_deadline < block.timestamp) revert DeadlinePassed();

        address _tokenIn = _path[0];
        address _tokenOut = _path[1];
        SwapStorage memory _storage = _getPointerToStorage().swapStorage;
        uint256 _token0OverToken1Price = getPrice();

        // Checks: path length is 2 && path must contain token0 and token1 only
        requireValidPath({ _path: _path, _token0: _storage.token0, _token1: _storage.token1 });

        // Calculations: determine amounts based on path

        uint256 _amountOut = _tokenOut == _storage.token0
            ? getAmount0Out(_amountIn, _token0OverToken1Price, _storage.token0PurchaseFee)
            : getAmount1Out(_amountIn, _token0OverToken1Price, _storage.token1PurchaseFee);

        // Checks: amountOut must not be smaller than the amountOutMin
        if (_amountOut < _amountOutMin) revert InsufficientOutputAmount();

        // Interactions: transfer tokens from msg.sender to this contract
        IERC20(_tokenIn).safeTransferFrom({ from: msg.sender, to: address(this), value: _amountIn });

        // Effects: swap tokens
        if (_tokenOut == _storage.token0) {
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
    ) external {
        // Checks: block.timestamp must be less than deadline
        if (_deadline < block.timestamp) revert DeadlinePassed();

        address _tokenIn = _path[0];
        address _tokenOut = _path[1];
        SwapStorage memory _storage = _getPointerToStorage().swapStorage;
        uint256 _token0OverToken1Price = getPrice();

        // Checks: path length is 2 && path must contain token0 and token1 only
        requireValidPath({ _path: _path, _token0: _storage.token0, _token1: _storage.token1 });

        // Calculations: determine amounts based on path
        uint256 _amountIn = _tokenIn == _storage.token0
            ? getAmount0In(_amountOut, _token0OverToken1Price, _storage.token1PurchaseFee)
            : getAmount1In(_amountOut, _token0OverToken1Price, _storage.token0PurchaseFee);
        // Checks: amountInMax must be larger or equal to than the amountIn
        if (_amountIn > _amountInMax) revert ExcessiveInputAmount();

        // Interactions: transfer tokens from msg.sender to this contract
        IERC20(_tokenIn).safeTransferFrom({ from: msg.sender, to: address(this), value: _amountIn });

        // Effects: swap tokens
        if (_tokenOut == _storage.token0) {
            swap({ _amount0Out: _amountOut, _amount1Out: 0, _to: _to, _data: new bytes(0) });
        } else {
            swap({ _amount0Out: 0, _amount1Out: _amountOut, _to: _to, _data: new bytes(0) });
        }
    }

    /// @notice The ```sync``` function syncs the reserves of the pair
    /// @dev This function is used to sync the reserves of the pair
    function sync() external {
        SwapStorage memory _storage = _getPointerToStorage().swapStorage;
        _sync(IERC20(_storage.token0).balanceOf(address(this)), IERC20(_storage.token1).balanceOf(address(this)));
    }

    /// @notice The ```_sync``` function syncs the reserves of the pair
    /// @param _token0balance The balance of token0
    /// @param _token1Balance The balance of token1
    function _sync(uint256 _token0balance, uint256 _token1Balance) internal {
        _getPointerToStorage().swapStorage.reserve0 = _token0balance.toUint112();
        _getPointerToStorage().swapStorage.reserve1 = _token1Balance.toUint112();
    }

    /// @notice The ```calculatePrice``` function calculates the current price of the pair using a simple compounding model
    /// @param _lastUpdated The timestamp of the last price update
    /// @param _currentTimestamp The current timestamp
    /// @param _interestRate The per second interest rate
    /// @param _basePrice The base price of the pair
    /// @return _currentPrice The current price of the pair
    function calculatePrice(
        uint256 _lastUpdated,
        uint256 _currentTimestamp,
        uint256 _interestRate,
        uint256 _basePrice
    ) public pure returns (uint256 _currentPrice) {
        // Calculate the time elapsed since the last price update
        uint256 timeElapsed = _currentTimestamp - _lastUpdated;
        // Calculate the compounded price
        _currentPrice = (_basePrice + _interestRate * timeElapsed);
    }

    /// @notice The ```getPrice``` function returns the current price of the pair
    /// @return _currentPrice The current price of the pair
    function getPrice() public view virtual returns (uint256 _currentPrice) {
        SwapStorage memory _swapStorage = _getPointerToStorage().swapStorage;
        uint256 _lastUpdated = _swapStorage.priceLastUpdated;
        uint256 _currentTimestamp = block.timestamp;
        uint256 _basePrice = _swapStorage.basePrice;
        uint256 _interestRate = _swapStorage.perSecondInterestRate;
        _currentPrice = calculatePrice({
            _lastUpdated: _lastUpdated,
            _currentTimestamp: _currentTimestamp,
            _interestRate: _interestRate,
            _basePrice: _basePrice
        });
    }

    //==============================================================================
    // Events
    //==============================================================================

    /// @notice The ```SetTokenReceiver``` event is emitted when the token receiver is set
    /// @param tokenReceiver The address of the token receiver
    event SetTokenReceiver(address indexed tokenReceiver);

    /// @notice The ```SetApprovedSwapper``` event is emitted when the approved swapper is set
    /// @param approvedSwapper The address of the approved swapper
    /// @param isApproved The boolean value indicating whether the swapper is approved
    event SetApprovedSwapper(address indexed approvedSwapper, bool isApproved);

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

    event SetTokenPurchaseFees(uint256 token0PurchaseFee, uint256 token1PurchaseFee);

    /// @notice The ```RemoveTokens``` event is emitted when tokens are removed
    /// @param tokenAddress The address of the token
    /// @param amount The amount of tokens to remove
    event RemoveTokens(address indexed tokenAddress, uint256 amount);

    /// @notice The ```AddTokens``` event is emitted when tokens are added
    /// @param tokenAddress The address of the token
    /// @param from The address of the sender
    /// @param amount The amount of tokens to add
    event AddTokens(address indexed tokenAddress, address from, uint256 amount);

    /// @notice The ```SetPaused``` event is emitted when the pair is paused
    /// @param isPaused The boolean value indicating whether the pair is paused
    event SetPaused(bool isPaused);

    /// @notice Emitted when the price bounds are set
    /// @param minBasePrice The minimum allowed initial base price
    /// @param maxBasePrice The maximum allowed initial base price
    /// @param minAnnualizedInterestRate The minimum allowed annualized interest rate
    /// @param maxAnnualizedInterestRate The maximum allowed annualized interest rate
    event SetOraclePriceBounds(
        uint256 minBasePrice,
        uint256 maxBasePrice,
        uint256 minAnnualizedInterestRate,
        uint256 maxAnnualizedInterestRate
    );

    /// @notice Emitted when the price is configured
    /// @param basePrice The base price of the pair
    /// @param annualizedInterestRate The annualized interest rate
    event ConfigureOraclePrice(uint256 basePrice, uint256 annualizedInterestRate);

    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

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

    /// @notice Emitted when the reserve is insufficient
    error InsufficientLiquidity();

    /// @notice Emitted when the token purchase fee is invalid
    error InvalidToken0PurchaseFee();

    error InvalidToken1PurchaseFee();

    error ExcessiveInputAmount();

    error InsufficientOutputAmount();

    error InsufficientInputAmount();

    error PairIsPaused();

    /// @notice Emitted when the price is out of bounds
    error BasePriceOutOfBounds();

    /// @notice Emitted when the annualized interest rate is out of bounds
    error AnnualizedInterestRateOutOfBounds();

    /// @notice Emitted when the min base price is greater than the max base price
    error MinBasePriceGreaterThanMaxBasePrice();

    /// @notice Emitted when the min annualized interest rate is greater than the max annualized interest rate
    error MinAnnualizedInterestRateGreaterThanMax();
}
