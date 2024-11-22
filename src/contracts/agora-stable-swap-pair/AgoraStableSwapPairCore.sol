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
}

contract AgoraStableSwapPairCore is
    Initializable,
    AgoraStableSwapAccessControl,
    AgoraCompoundingOracle,
    AgoraStableSwapPairStorage
{
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
        _assignRole({ _role: APPROVED_SWAPPER, _newAddress: _approvedSwapper, _addRole: _isApproved });

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

    event RemoveTokens(address indexed tokenAddress, uint256 amount);

    function removeTokens(address _tokenAddress, uint256 _amount) external {
        // Checks: Only the token remover can remove tokens
        _requireIsRole({ _role: TOKEN_REMOVER_ROLE, _address: msg.sender });

        AgoraStableSwapPairStorage memory _storage = _getPointerToAgoraStableSwapStorage();

        // address _to =
        if (
            _tokenAddress != _storage.token0 &&
            _tokenAddress != _storage.token1
        ) revert("Invalid Token Address");
        IERC20(_tokenAddress).safeTransfer(_to, _amount);

        // TODO: update reserves

        // emit event
        emit RemoveTokens({ tokenAddress: _tokenAddress, amount: _amount });
    }

    event AddTokens(address indexed tokenAddress, address indexed from, uint256 amount);

    function addTokens(address _tokenAddress, address _from, uint256 _amount) external {
        // Checks: Only the token adder can add tokens
        _requireIsRole({ _role: TOKEN_ADDER_ROLE, _address: msg.sender });

        AgoraStableSwapPairStorage memory _storage = _getPointerToAgoraStableSwapStorage();

        // address _to =
        if (
            _tokenAddress != _storage.token0 &&
            _tokenAddress != _storage.token1
        ) revert("Invalid Token Address");
        IERC20(_tokenAddress).safeTransferFrom(_from, address(this), _amount);

        // TODO: update reserves


        // emit event
        emit RemoveTokens({ tokenAddress: _tokenAddress, from: _from, amount: _amount });
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

    function swap(uint256 _amount0Out, uint256 _amount1Out, address _to, bytes calldata _data) external nonreentrant {
        _requireSenderIsRole(APPROVED_SWAPPER);
        // Force one amountOut to be 0
        if (_amount0Out != 0 && _amount1Out != 0) revert("Invalid Swap Amounts");

        AgoraStableSwapPairStorage memory _storage = _getPointerToAgoraStableSwapStorage();

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
    }

    function getAmountsOut(
        address _empty,
        uint256 _amountIn,
        address[] memory _path
    ) external view returns (uint256[] memory _amounts) {
        // enforce parameter sizes
        if (_path.length != 2) revert("Invalid Path");
        // make sure token0 exists in the path
        if (_token0 != _path[0] || _token1 != _path[1]) revert("Invalid Path");
        // make sure token1 exists in the path
        if (_token1 != _path[0] || _token0 != _path[1]) revert("Invalid Path");

        AgoraStableSwapPairStorage memory _storage = _getPointerToAgoraStableSwapStorage();

        address _token0 = _storage.token0;
        address _token1 = _storage.token1;
        uint256 _price = getPrice();


        // path[1] represents our tokenOut
        if (_path[1] == _token0) {
            _amountOut = _getAmount0Out(_amountIn, _price, _storage.token0PurchaseFee);
        } else {
            _amountOut = _getAmount1Out(_amountIn, _price, _storage.token1PurchaseFee);
        }

        _amounts = new uint256[](2);
        _amounts[0] = _amountIn;
        _amounts[1] = _amountOut;
    }

    function getAmountsIn(
        address _empty,
        uint256 _amountOut,
        address[] memory _path
    ) external view returns (uint256[] memory _amounts) {
        // enforce parameter sizes
        if (_path.length != 2) revert("Invalid Path");
        // make sure token0 exists in the path
        if (_token0 != _path[0] || _token1 != _path[1]) revert("Invalid Path");
        // make sure token1 exists in the path
        if (_token1 != _path[0] || _token0 != _path[1]) revert("Invalid Path");

        AgoraStableSwapPairStorage memory _storage = _getPointerToAgoraStableSwapStorage();

        address _token0 = _storage.token0;
        address _token1 = _storage.token1;
        uint256 _price = getPrice();

        // path[0] represents our tokenIn
        if (_path[0] == _token0) {
            _amountIn = _getAmount0In(_amountOut, _price, _storage.token0PurchaseFee);
        } else {
            _amountIn = _getAmount1In(_amountOut, _price, _storage.token1PurchaseFee);
        }

        _amounts = new uint256[](2);
        _amounts[0] = _amountIn;
        _amounts[1] = _amountOut;
    }

    function swapExactTokensForTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to
    ) external nonreentrant {
        // TODO: look into implementing deadline here
        address _empty = address(0);
        uint256[] memory _amounts = getAmountsOut(_empty, _amountIn, _path);
        // CHECKS: amountOut must not be smaller than the amountOutMin
        // NOTE: this assumes no multihopping, otherwise we need to do len()-1 to get final amountOut
        if (_amounts[1] < _amountOutMin) revert("Insufficient Output Amount");

        // EFFECTS: transfer tokens from msg.sender to this contract
        IERC20(_path[0]).safeTransferFrom(msg.sender, address(this), _amountIn);

        // EFFECTS: swap tokens
        swap(_amounts[0], _amounts[1], _to, "");
    }

    function swapTokensForExactTokens(uint256 _amountOut, uint256 _amountInMax, address[] calldata _path, address _to) external nonreentrant {
        // TODO: implement deadline here?
        address _empty = address(0);
        uint256[] memory _amounts = getAmountsIn(_empty, _amountOut, _path);
        // CHECKS: amountInMax must not be smaller than the amountIn
        if (_amounts[0] > _amountInMax) revert("Amount In Max Exceeded");

        // EFFECTS: transfer tokens from msg.sender to this contract
        IERC20(_path[1]).safeTransferFrom(msg.sender, address(this), _amountInMax);

        // EFFECTS: swap tokens
        swap(_amounts[0], _amounts[1], _to, "");
    }

    //==============================================================================
    // View Helper Functions
    //==============================================================================


    function _getAmount0In(uint256 _amountOut, uint256 _price, uint256 _purchaseFeeToken0) internal pure returns (uint256 _amountIn) {
        _amountIn = (_amountOut * _price) / ((PRECISION - _purchaseFeeToken0) * PRECISION);
    }

    function _getAmount1In(uint256 _amountOut, uint256 _price, uint256 _purchaseFeeToken1) internal pure returns (uint256 _amountIn) {
        _amountIn = _amountOut / ((PRECISION - _purchaseFeeToken1) * _price);
    }

    function _getAmount0Out(uint256 _amountIn, uint256 _price, uint256 _purchaseFeeToken0) internal pure returns (uint256 _amountOut) {
        _amountOut = (_amountIn * (PRECISION - _purchaseFeeToken0) * _price) /  PRECISION;
    }

    function _getAmount1Out(uint256 _amountIn, uint256 _price, uint256 _purchaseFeeToken1) internal pure returns (uint256 _amountOut) {
        _amountOut = (_amountIn * (PRECISION - _purchaseFeeToken1)) / _price;
    }

}
