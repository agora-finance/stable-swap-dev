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
// ================ AgoraStableSwapManagerConfiguration ===================
// ====================================================================

import { IAgoraStableSwapPair } from "../interfaces/IAgoraStableSwapPair.sol";
import { AgoraStableSwapManagerAccessControl } from "./AgoraStableSwapManagerAccessControl.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

struct ConstructorParams {
    address stableSwapPairAddress;
    uint256 minToken0PurchaseFee; // 18 decimals precision, max value 1
    uint256 maxToken0PurchaseFee; // 18 decimals precision, max value 1
    uint256 minToken1PurchaseFee; // 18 decimals precision, max value 1
    uint256 maxToken1PurchaseFee; // 18 decimals precision, max value 1
    uint256 minBasePrice; // 18 decimals precision, max value determined by difference between decimals of token0 and token1
    uint256 maxBasePrice; // 18 decimals precision, max value determined by difference between decimals of token0 and token1
    int256 minAnnualizedInterestRate; // 18 decimals precision, given as number i.e. 1e16 = 1%
    int256 maxAnnualizedInterestRate; // 18 decimals precision, given as number i.e. 1e16 = 1%
}

/// @title AgoraStableSwapManagerConfiguration
/// @notice The AgoraStableSwapManagerConfiguration is a contract that manages the privileged configuration setters for the AgoraStableSwapPair
/// @author Agora
contract AgoraStableSwapManagerConfiguration is AgoraStableSwapManagerAccessControl {
    using SafeCast for *;
    using SafeERC20 for IERC20;

    address public immutable stableSwapPairAddress;
    uint256 public minToken0PurchaseFee; // 18 decimals precision, max value 1
    uint256 public maxToken0PurchaseFee; // 18 decimals precision, max value 1
    uint256 public minToken1PurchaseFee; // 18 decimals precision, max value 1
    uint256 public maxToken1PurchaseFee; // 18 decimals precision, max value 1
    uint256 public minBasePrice; // 18 decimals precision, max value determined by difference between decimals of token0 and token1
    uint256 public maxBasePrice; // 18 decimals precision, max value determined by difference between decimals of token0 and token1
    int256 public minAnnualizedInterestRate; // 18 decimals precision, given as number i.e. 1e16 = 1%
    int256 public maxAnnualizedInterestRate; // 18 decimals precision, given as number i.e. 1e16 = 1%

    constructor(ConstructorParams memory _params) {
        stableSwapPairAddress = _params.stableSwapPairAddress;
        minToken0PurchaseFee = _params.minToken0PurchaseFee;
        maxToken0PurchaseFee = _params.maxToken0PurchaseFee;
        minToken1PurchaseFee = _params.minToken1PurchaseFee;
        maxToken1PurchaseFee = _params.maxToken1PurchaseFee;
        minBasePrice = _params.minBasePrice;
        maxBasePrice = _params.maxBasePrice;
        minAnnualizedInterestRate = _params.minAnnualizedInterestRate;
        maxAnnualizedInterestRate = _params.maxAnnualizedInterestRate;
    }

    //==============================================================================
    // Privileged Configuration Functions
    //==============================================================================

    /// @notice The ```setFeeBounds``` function sets the fee bounds
    /// @param _minToken0PurchaseFee The minimum purchase fee for token0
    /// @param _maxToken0PurchaseFee The maximum purchase fee for token0
    /// @param _minToken1PurchaseFee The minimum purchase fee for token1
    /// @param _maxToken1PurchaseFee The maximum purchase fee for token1
    function setFeeBounds(
        uint256 _minToken0PurchaseFee,
        uint256 _maxToken0PurchaseFee,
        uint256 _minToken1PurchaseFee,
        uint256 _maxToken1PurchaseFee
    ) public {
        // Checks: Only the admin can set the fee bounds
        _requireSenderIsRole({ _role: ACCESS_CONTROL_ADMIN_ROLE });

        // Effects: Set the fee bounds
        minToken0PurchaseFee = _minToken0PurchaseFee;
        maxToken0PurchaseFee = _maxToken0PurchaseFee;
        minToken1PurchaseFee = _minToken1PurchaseFee;
        maxToken1PurchaseFee = _maxToken1PurchaseFee;

        emit SetFeeBounds({
            minToken0PurchaseFee: _minToken0PurchaseFee,
            maxToken0PurchaseFee: _maxToken0PurchaseFee,
            minToken1PurchaseFee: _minToken1PurchaseFee,
            maxToken1PurchaseFee: _maxToken1PurchaseFee
        });
    }

    function setTokenPurchaseFees(uint256 _token0PurchaseFee, uint256 _token1PurchaseFee) public {
        // Checks: Only the fee setter can set the fee
        _requireIsRole({ _role: FEE_SETTER_ROLE, _address: msg.sender });

        // Checks: Ensure the params are valid and within the bounds
        if (_token0PurchaseFee < minToken0PurchaseFee || _token0PurchaseFee > maxToken0PurchaseFee) {
            revert InvalidToken0PurchaseFee();
        }
        if (_token1PurchaseFee < minToken1PurchaseFee || _token1PurchaseFee > maxToken1PurchaseFee) {
            revert InvalidToken1PurchaseFee();
        }

        // Interactions: Set the token purchase fees
        IAgoraStableSwapPair(stableSwapPairAddress).setTokenPurchaseFees({
            _token0PurchaseFee: _token0PurchaseFee,
            _token1PurchaseFee: _token1PurchaseFee
        });

        // emit event
        emit SetTokenPurchaseFees({ token0PurchaseFee: _token0PurchaseFee, token1PurchaseFee: _token1PurchaseFee });
    }

    /// @notice The ```removeTokens``` function removes tokens from the pair
    /// @param _tokenAddress The address of the token
    /// @param _amount The amount of tokens to remove
    function removeTokens(address _tokenAddress, uint256 _amount) external {
        // Checks: Only the token remover can remove tokens
        _requireIsRole({ _role: TOKEN_REMOVER_ROLE, _address: msg.sender });

        // Interactions: Remove the tokens
        IAgoraStableSwapPair(stableSwapPairAddress).removeTokens({ _tokenAddress: _tokenAddress, _amount: _amount });

        // emit event
        emit RemoveTokens({ tokenAddress: _tokenAddress, amount: _amount });
    }

    /// @notice The ```collectFees``` function removes accumulated fees from the pair
    /// @param _tokenAddress The address of the token
    /// @param _amount The amount of tokens to remove
    function collectFees(address _tokenAddress, uint256 _amount) external {
        // Checks: Only the tokenRemover can remove tokens
        _requireIsRole({ _role: TOKEN_REMOVER_ROLE, _address: msg.sender });

        // Interactions: Collect the fees
        IAgoraStableSwapPair(stableSwapPairAddress).collectFees({ _tokenAddress: _tokenAddress, _amount: _amount });

        // emit event
        emit CollectFees({ tokenAddress: _tokenAddress, amount: _amount });
    }

    /// @notice The ```setPaused``` function sets the paused state of the pair
    /// @param _setPaused The boolean value indicating whether the pair is paused
    function setPaused(bool _setPaused) public {
        // Checks: Only the pauser can pause the pair
        _requireIsRole({ _role: PAUSER_ROLE, _address: msg.sender });

        // Interactions: Set the isPaused state
        IAgoraStableSwapPair(stableSwapPairAddress).setPaused({ _setPaused: _setPaused });

        // emit event
        emit SetPaused({ isPaused: _setPaused });
    }

    /// @notice The ```setOraclePriceBounds``` function sets the price bounds for the pair
    /// @dev Only the admin can set the price bounds
    /// @param _minBasePrice The minimum allowed initial base price
    /// @param _maxBasePrice The maximum allowed initial base price
    /// @param _minAnnualizedInterestRate The minimum allowed annualized interest rate
    /// @param _maxAnnualizedInterestRate The maximum allowed annualized interest rate
    function setOraclePriceBounds(
        uint256 _minBasePrice,
        uint256 _maxBasePrice,
        int256 _minAnnualizedInterestRate,
        int256 _maxAnnualizedInterestRate
    ) public {
        _requireSenderIsRole({ _role: ACCESS_CONTROL_ADMIN_ROLE });
        // Check that the parameters are valid
        if (_minBasePrice > _maxBasePrice) revert MinBasePriceGreaterThanMaxBasePrice();
        if (_minAnnualizedInterestRate > _maxAnnualizedInterestRate) revert MinAnnualizedInterestRateGreaterThanMax();

        minBasePrice = _minBasePrice;
        maxBasePrice = _maxBasePrice;
        minAnnualizedInterestRate = _minAnnualizedInterestRate;
        maxAnnualizedInterestRate = _maxAnnualizedInterestRate;

        emit SetOraclePriceBounds({
            minBasePrice: _minBasePrice,
            maxBasePrice: _maxBasePrice,
            minAnnualizedInterestRate: _minAnnualizedInterestRate,
            maxAnnualizedInterestRate: _maxAnnualizedInterestRate
        });
    }

    /// @notice The ```configureOraclePrice``` function configures the price of the pair
    /// @dev Only the price setter can configure the price
    /// @param _basePrice The base price of the pair
    /// @param _annualizedInterestRate The annualized interest rate
    function configureOraclePrice(uint256 _basePrice, int256 _annualizedInterestRate) public {
        _requireSenderIsRole({ _role: PRICE_SETTER_ROLE });

        // Check that the price is within bounds
        if (_basePrice < minBasePrice || _basePrice > maxBasePrice) revert BasePriceOutOfBounds();
        if (
            _annualizedInterestRate < minAnnualizedInterestRate || _annualizedInterestRate > maxAnnualizedInterestRate
        ) {
            revert AnnualizedInterestRateOutOfBounds();
        }

        // Interactions: Configure the price
        IAgoraStableSwapPair(stableSwapPairAddress).configureOraclePrice({
            _basePrice: _basePrice,
            _annualizedInterestRate: _annualizedInterestRate
        });

        // emit eventd
        emit ConfigureOraclePrice(_basePrice, _annualizedInterestRate);
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
        int256 minAnnualizedInterestRate,
        int256 maxAnnualizedInterestRate
    );

    /// @notice Emitted when the price is configured
    /// @param basePrice The base price of the pair
    /// @param annualizedInterestRate The annualized interest rate
    event ConfigureOraclePrice(uint256 basePrice, int256 annualizedInterestRate);

    /// @notice Emitted when a swap is executed
    /// @param sender The address of the sender
    /// @param amount0In The amount of token0 in
    /// @param amount1In The amount of token1 in
    /// @param amount0Out The amount of token0 out
    /// @param amount1Out The amount of token1 out
    /// @param to The address of the recipient
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    /// @notice Emitted when fees are accumulated
    /// @param token0FeesAccumulated The amount of token0 accumulated as fees
    /// @param token1FeesAccumulated The amount of token1 accumulated as fees
    event SwapFees(uint256 token0FeesAccumulated, uint256 token1FeesAccumulated);

    /// @notice Emitted when the reserves are synced
    /// @param reserve0 The reserve of token0
    /// @param reserve1 The reserve of token1
    event Sync(uint256 reserve0, uint256 reserve1);

    /// @notice Emitted when the fee receiver is set
    /// @param feeReceiver The address of the fee receiver
    event SetFeeReceiver(address indexed feeReceiver);

    // ============================================================================================
    // Errors
    // ============================================================================================

    /// @notice Emitted when an invalid token is passed to a function
    error InvalidTokenAddress();

    /// @notice Emitted when an invalid path is passed to a function
    error InvalidPath();

    /// @notice Emitted when an invalid path length is passed to a function
    error InvalidPathLength();

    /// @notice Emitted when both amounts cannot be non-zero
    error InvalidSwapAmounts();

    /// @notice Emitted when the deadline is passed
    error Expired();

    /// @notice Emitted when the reserve is insufficient
    error InsufficientLiquidity();

    /// @notice Emitted when the token purchase fee is invalid
    error InvalidToken0PurchaseFee();

    /// @notice Emitted when the token1 purchase fee is invalid
    error InvalidToken1PurchaseFee();

    /// @notice Emitted when the input amount is excessive
    error ExcessiveInputAmount();

    /// @notice Emitted when the output amount is insufficient
    error InsufficientOutputAmount();

    /// @notice Emitted when the input amount is insufficient
    error InsufficientInputAmount();

    /// @notice Emitted when the pair is paused
    error PairIsPaused();

    /// @notice Emitted when the price is out of bounds
    error BasePriceOutOfBounds();

    /// @notice Emitted when the annualized interest rate is out of bounds
    error AnnualizedInterestRateOutOfBounds();

    /// @notice Emitted when the min base price is greater than the max base price
    error MinBasePriceGreaterThanMaxBasePrice();

    /// @notice Emitted when the min annualized interest rate is greater than the max annualized interest rate
    error MinAnnualizedInterestRateGreaterThanMax();

    /// @notice Emitted when there are insufficient tokens available for withrawal
    error InsufficientTokens();

    /// @notice Emitted when the decimals of the tokens are invalid during initialization
    error IncorrectDecimals();

    /// @notice The ```CollectFees``` event is emitted when fees are collected
    /// @param tokenAddress The address of the token
    /// @param amount The amount of tokens collected
    event CollectFees(address indexed tokenAddress, uint256 amount);
}
