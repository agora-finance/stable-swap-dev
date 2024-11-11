// SPDX-License-Identifier: ISC
pragma solidity ^0.8.28;

import { AgoraStableSwapAccessControl } from "./AgoraStableSwapAccessControl.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IUniswapV2Callee } from "./interfaces/IUniswapV2Callee.sol";

struct ConstructorParams {
    address token0;
    address token1;
    uint256 token0to1Fee;
    address oracleAddress;
    address initialFeeSetter;
}

contract AgoraStableSwap is AgoraStableSwapAccessControl {
    using SafeERC20 for IERC20;

    uint256 public constant PRECISION = 1e18;

    struct AgoraStableSwapStorage {
        address token0;
        address token1;
        uint256 token0PurchaseFee; // 18 decimals
        uint256 token1PurchaseFee; // 18 decimals
        address oracleAddress;
        address token0OverToken1Price; // given as token1's price in token0
        uint256 reserve0;
        uint256 reserve1;
        uint256 lastBlock;
    }

    enum Token {
        token0,
        token1
    }

    constructor(ConstructorParams memory _params) {
        // Set the token0 and token1
        _getPointerToAgoraStableSwapStorage().token0 = _params.token0;
        _getPointerToAgoraStableSwapStorage().token1 = _params.token1;

        // Set the token0to1Fee and token1to0Fee
        _getPointerToAgoraStableSwapStorage().token0to1Fee = _params.token0to1Fee;
        _getPointerToAgoraStableSwapStorage().token1to0Fee = _params.token1to0Fee;

        // Set the oracle address
        _getPointerToAgoraStableSwapStorage().oracleAddress = _params.oracleAddress;

        // Set the fee setter
        _setRoleMembership({ _role: FEE_SETTER_ROLE, _address: _params.initialFeeSetter, _insert: true });
        emit RoleAssigned({ role: FEE_SETTER_ROLE, address_: _params.initialFeeSetter });

    }


    modifier nonreentrant {
        assembly {
            if tload(AGORA_STABLE_SWAP_TRANSIENT_LOCK_SLOT) { revert(0, 0) }
            tstore(AGORA_STABLE_SWAP_TRANSIENT_LOCK_SLOT, 1)
        }
        _;
        // Unlocks the guard, making the pattern composable.
        // After the function exits, it can be called again, even in the same transaction.
        assembly {
            tstore(AGORA_STABLE_SWAP_TRANSIENT_LOCK_SLOT, 0)
        }
    }

    event SetTokenPurchaseFee(Token indexed token, uint256 _tokenPurchaseFee);

    function setTokenPurchaseFee(Token _token, uint256 _tokenPurchaseFee) public {
        // Checks: Only the fee setter can set the fee
        _requireIsRole({ _role: FEE_SETTER_ROLE, _address: msg.sender });
        
        // Effects: Set the token1to0Fee
        if (_token == Token.token0) {
            _getPointerToAgoraStableSwapStorage().token0PurchaseFee = _tokenPurchaseFee;
        } else {
            _getPointerToAgoraStableSwapStorage().token1PurchaseFee = _tokenPurchaseFee;
        }

        // emit event
        emit SetTokenPurchaseFee({ token: _token, tokenPurchaseFee: _tokenPurchaseFee });
    }

    function getPrice() external view returns (uint256) {
        return IOracle(_getPointerToAgoraStableSwapStorage().oracleAddress).getPrice();
    }

    function swap(uint _amount0Out, uint _amount1Out, address _to, bytes calldata _data) external nonreentrant {
        // Force one amountOut to be 0
        if (_amount0Out != 0 && _amount1Out != 0) {
            revert ("Invalid Swap Amounts");
        }

        // Cache information about the pair for gas savings
        address _token0 = _getPointerToAgoraStableSwapStorage().token0;
        address _token1 = _getPointerToAgoraStableSwapStorage().token1;
        uint256 _reserve0 = _getPointerToAgoraStableSwapStorage().reserve0;
        uint256 _reserve1 = _getPointerToAgoraStableSwapStorage().reserve1;
        uint256 _price = _getPrice();

        // Check for proper liquidity available
        if (_amount0Out >= _reserve0 || _amount1Out >= _reserve1) {
            revert ("Insufficient Liquidity");
        }
        
        // Send the tokens (you can only send 1)
        if (_amount0Out > 0) {
            IERC20(_token0).safeTransfer(to, _amount0Out);
        } else {
            IERC20(_token1).safeTransfer(to, _amount1Out);
        }
        // Execute the callback
        if (data.length > 0) IUniswapV2Callee(_to).uniswapV2Call({ sender: msg.sender, amount0: _amount0Out, amount1: _amount1Out, data: _data });
        // Take snapshot of balances
        uint256 _finalToken0Balance = IERC20(_token0).balanceOf(address(this));
        uint256 _finalToken1Balance = IERC20(_token1).balanceOf(address(this));
        
        // Calculate how many tokens were transferred
        uint256 _token0In = _finalToken0Balance > _reserve0 ? _finalToken0Balance - _reserve0 : 0;
        uint256 _token1In = _finalToken1Balance > _reserve1 ? _finalToken1Balance - _reserve1 : 0;

        // Check we received some tokens
        if (_token0In == 0 && _token1In == 0) {
            revert ("No Tokens Received");
        }

        // Check that we received the correct amount of tokens
        if (_amount0Out > 0) {
            uint256 _expectedAmount0Out = _token1In * price * (1e18 - _getPointerToAgoraStableSwapStorage().token0PurchaseFee) / 1e18;
            if (_expectedAmount0Out > _reserve0 - _finalToken0Balance) {
                revert ("Invalid Swap");
            }
        } else {
            uint256 _expectedAmount1Out = _token0In * (1e18 - _getPointerToAgoraStableSwapStorage().token1PurchaseFee) / price;
            if (_expectedAmount1Out > _reserve1 - _finalToken1Balance) {
                revert ("Invalid Swap");
            }
        }
    }

    //==============================================================================
    // View Helper Functions
    //==============================================================================

    function getAmountIn(Token _token, uint256 _amountOut) external view returns (uint256 _amountIn) {
        uint256 _price = _getPrice();
        if (_token == Token.token0) {
            _amountIn = _amountOut * price / (PRECISION - _getPointerToAgoraStableSwapStorage().token0PurchaseFee);
        } else {
            _amountIn = _amountOut / ((PRECISION - _getPointerToAgoraStableSwapStorage().token1PurchaseFee) * price);
        }
    }s

    //==============================================================================
    // Erc 7201: UnstructuredNamespace Storage Functions
    //==============================================================================

    /// @notice The ```AGORA_STABLE_SWAP_STORAGE_SLOT``` is the storage slot for the AgoraStableSwapStorage struct
    /// @dev keccak256(abi.encode(uint256(keccak256("AgoraStableSwapStorage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant AGORA_STABLE_SWAP_STORAGE_SLOT =
        0x8f8de9240b3899c03a31968f466af060ab1c78464aa7ae14941c20fe7917b000;

    /// @notice The ```_getPointerToAgoraStableSwapStorage``` function returns a pointer to the AgoraStableSwapStorage struct
    /// @return $ A pointer to the AgoraStableSwapStorage struct
    function _getPointerToAgoraStableSwapStorage()
        internal
        pure
        returns (AgoraStableSwapStorage storage $)
    {
        /// @solidity memory-safe-assembly
        assembly {
            $.slot := AGORA_STABLE_SWAP_STORAGE_SLOT
        }
    }

        /// @notice The ```AGORA_STABLE_SWAP_TRANSIENT_LOCK_SLOT``` is the storage slot for the re-entrancy lock
    /// @dev keccak256(abi.encode(uint256(keccak256("AgoraStableSwapStorage.TransientReentrancyLock")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant AGORA_STABLE_SWAP_TRANSIENT_LOCK_SLOT =
        0x1c912e2d5b9a8ca13ccf418e7dc8bfe55d8292938ebaef5b3166abbe45f04b00;
}