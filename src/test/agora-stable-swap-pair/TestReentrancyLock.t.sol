// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "../BaseTest.sol";

contract TestReentrancyLock is BaseTest {
    /// FEATURE:

    address payable public bob = labelAndDeal("bob");
    address payable public alice = labelAndDeal("alice");
    UniswapV2Callee _callee;

    function setUp() public virtual {
        /// BACKGROUND:
        _defaultSetup();

        _callee = new UniswapV2Callee();
        _setApprovedSwapperAsWhitelister(pair, address(_callee));
    }

    function test_CannotReenterSwap() public {
        _seedErc20(pair.token0(), address(this), 1000);
        pair.sync();
        IERC20(pair.token0()).transfer(address(pair), 100);
        vm.expectRevert();
        pair.swap(100, 0, address(_callee), abi.encode(address(pair)));
    }
}

contract UniswapV2Callee {
    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        console.log("inside the uniswapV2Call");
        AgoraStableSwapPair(abi.decode(data, (address))).swap(100, 0, address(this), new bytes(0));
    }
}
