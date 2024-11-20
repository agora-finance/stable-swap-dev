// SPDX-License-Identifier: ISC
pragma solidity ^0.8.28;

import { AgoraStableSwapAccessControl } from "./AgoraStableSwapAccessControl.sol";

import { IUniswapV2Callee } from "../interfaces/IUniswapV2Callee.sol";
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
}

interface IOracle {
    function getPrice() external view returns (uint256);
}

contract AgoraStableSwapPairCore is Initializable, AgoraStableSwapAccessControl, AgoraStableSwapPairStorage {
    using SafeERC20 for IERC20;

    uint256 public constant PRECISION = 1e18;

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

    enum Token {
        token0,
        token1
    }

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
    // Privileged  Functions
    //==============================================================================

    event SetApprovedSwapper(address indexed approvedSwapper, bool isApproved);

    function setApprovedSwapper(address _approvedSwapper, bool _isApproved) public {
        // Checks: Only the fee setter can set the fee
        _requireIsRole({ _role: WHITELISTER_ROLE, _address: msg.sender });

        // Effects: Set the isApproved state
        _setRoleMembership({ _role: APPROVED_SWAPPER, _address: _approvedSwapper, _insert: _isApproved });

        // emit event
        emit SetApprovedSwapper({ approvedSwapper: _approvedSwapper, isApproved: _isApproved });
    }

    event SetTokenPurchaseFee(Token indexed token, uint256 tokenPurchaseFee);

    function setTokenPurchaseFee(Token _token, uint256 _tokenPurchaseFee) public {
        // Checks: Only the fee setter can set the fee
        _requireIsRole({ _role: FEE_SETTER_ROLE, _address: msg.sender });

        // Effects: Set the token1to0Fee
        if (_token == Token.token0) _getPointerToAgoraStableSwapStorage().token0PurchaseFee = _tokenPurchaseFee;
        else _getPointerToAgoraStableSwapStorage().token1PurchaseFee = _tokenPurchaseFee;

        // emit event
        emit SetTokenPurchaseFee({ token: _token, tokenPurchaseFee: _tokenPurchaseFee });
    }

    event RemoveTokens(address indexed tokenAddress, address indexed to, uint256 amount);

    function removeTokens(address _tokenAddress, address _to, uint256 _amount) external {
        // Checks: Only the fee setter can set the fee
        _requireIsRole({ _role: TOKEN_REMOVER_ROLE, _address: msg.sender });
        if (
            _tokenAddress != _getPointerToAgoraStableSwapStorage().token0 &&
            _tokenAddress != _getPointerToAgoraStableSwapStorage().token1
        ) revert("Invalid Token Address");
        IERC20(_tokenAddress).safeTransfer(_to, _amount);

        // emit event
        emit RemoveTokens({ tokenAddress: _tokenAddress, to: _to, amount: _amount });
    }

    event SetPaused(bool isPaused);

    function setPaused(bool _isPaused) public {
        // Checks: Only the fee setter can set the fee
        _requireIsRole({ _role: PAUSER_ROLE, _address: msg.sender });

        // Effects: Set the isPaused state
        _getPointerToAgoraStableSwapStorage().isPaused = _isPaused;

        // emit event
        emit SetPaused({ isPaused: _isPaused });
    }

    function getPrice() public view returns (uint256) {
        return IOracle(_getPointerToAgoraStableSwapStorage().oracleAddress).getPrice();
    }

    function swap(uint256 _amount0Out, uint256 _amount1Out, address _to, bytes calldata _data) external nonreentrant {
        // Force one amountOut to be 0
        if (_amount0Out != 0 && _amount1Out != 0) revert("Invalid Swap Amounts");

        // Cache information about the pair for gas savings
        address _token0 = _getPointerToAgoraStableSwapStorage().token0;
        address _token1 = _getPointerToAgoraStableSwapStorage().token1;
        uint256 _reserve0 = _getPointerToAgoraStableSwapStorage().reserve0;
        uint256 _reserve1 = _getPointerToAgoraStableSwapStorage().reserve1;
        uint256 _price = getPrice();

        // Check for proper liquidity available
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
            uint256 _expectedAmount0Out = (_token1In *
                _price *
                (1e18 - _getPointerToAgoraStableSwapStorage().token0PurchaseFee)) / PRECISION;
            if (_expectedAmount0Out > _reserve0 - _finalToken0Balance) revert("Invalid Swap");
        } else {
            uint256 _expectedAmount1Out = (_token0In *
                (PRECISION - _getPointerToAgoraStableSwapStorage().token1PurchaseFee)) / _price;
            if (_expectedAmount1Out > _reserve1 - _finalToken1Balance) revert("Invalid Swap");
        }
    }

    function getAmountsOut(
        address _empty,
        uint256 _amountIn,
        address[] memory _path
    ) external view returns (uint256[] memory _amounts) {
        address _token0 = _getPointerToAgoraStableSwapStorage().token0;
        address _token1 = _getPointerToAgoraStableSwapStorage().token1;
        // enforce parameter sizes
        if (_path.length != 2) revert("Invalid Path");
        // make sure token0 exists in the path
        if (_token0 != _path[0] || _token1 != _path[1]) revert("Invalid Path");
        // make sure token1 exists in the path
        if (_token1 != _path[0] || _token0 != _path[1]) revert("Invalid Path");

        // path[1] represents our tokenOut
        Token _tokenOut = _path[1] == _token0 ? Token.token0 : Token.token1;
        uint256 _amountOut = getAmountOut(_tokenOut, _amountIn);

        _amounts = new uint256[](2);
        _amounts[0] = _amountIn;
        _amounts[1] = _amountOut;
    }

    function getAmountsIn(
        address _empty,
        uint256 _amountOut,
        address[] memory _path
    ) external view returns (uint256[] memory _amounts) {
        address _token0 = _getPointerToAgoraStableSwapStorage().token0;
        address _token1 = _getPointerToAgoraStableSwapStorage().token1;
        // enforce parameter sizes
        if (_path.length != 2) revert("Invalid Path");
        // make sure token0 exists in the path
        if (_token0 != _path[0] || _token1 != _path[1]) revert("Invalid Path");
        // make sure token1 exists in the path
        if (_token1 != _path[0] || _token0 != _path[1]) revert("Invalid Path");

        // path[0] represents our tokenIn
        Token _tokenIn = _path[0] == _token0 ? Token.token0 : Token.token1;
        uint256 _amountIn = getAmountIn(_tokenIn, _amountOut);

        _amounts = new uint256[](2);
        _amounts[0] = _amountIn;
        _amounts[1] = _amountOut;
    }

    // function swapExactTokensForTokens

    //==============================================================================
    // View Helper Functions
    //==============================================================================

    function getAmountIn(Token _tokenIn, uint256 _amountOut) public view returns (uint256 _amountIn) {
        uint256 _price = getPrice();
        if (_tokenIn == Token.token0) {
            _amountIn = (_amountOut * _price) / (PRECISION - _getPointerToAgoraStableSwapStorage().token1PurchaseFee);
        } else {
            _amountIn = _amountOut / ((PRECISION - _getPointerToAgoraStableSwapStorage().token0PurchaseFee) * _price);
        }
    }

    function getAmountOut(Token _tokenOut, uint256 _amountIn) public view returns (uint256 _amountOut) {
        uint256 _price = getPrice();
        if (_tokenOut == Token.token0) {
            _amountOut =
                (_amountIn * (PRECISION - _getPointerToAgoraStableSwapStorage().token1PurchaseFee) * _price) /
                (PRECISION * PRECISION);
        } else {
            _amountOut = (_amountIn * (PRECISION - _getPointerToAgoraStableSwapStorage().token0PurchaseFee)) / _price;
        }
    }
}
