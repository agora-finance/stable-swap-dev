// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "../BaseTest.sol";

contract TestMath is BaseTest {
    using NumberFormat for uint256;
    /// FEATURE:

    address payable public bob = labelAndDeal("bob");
    address payable public alice = labelAndDeal("alice");

    function setUp() public {
        /// BACKGROUND:
        _defaultSetup();
    }

    function test_GetAmount0Out_RoundsDown() public view {
        uint256 _price = uint256(1e36) / ((3e18 * 1e6) / 1e6);
        uint256 _fee = 0;
        uint256 _amountIn = 100;
        (uint256 _amountOut, ) = pair.getAmount0Out(_amountIn, _price, _fee);
        assertEq({ err: "///THEN _amountOut is equal to 33", left: _amountOut, right: 33 });
    }

    function test_GetAmount1Out_RoundsDown() public view {
        uint256 _price = uint256(1e36) / ((3e18 * 1e6) / 1e6);
        uint256 _fee = 0;
        uint256 _amountIn = 100;
        (uint256 _amountOut, ) = pair.getAmount0Out(_amountIn, _price, _fee);
        assertLe({ err: "///THEN _amountOut is equal to 33", left: _amountOut, right: 33 });
    }

    function test_GetAmount1In_RoundsUp() public view {
        uint256 _price = (3e18 * 1e6) / 1e6;
        uint256 _fee = 0;
        uint256 _amountOut = 100;
        (uint256 _amountIn, ) = pair.getAmount1In(_amountOut, _price, _fee);
        console.log("test_GetAmountIn_RoundsUp ~ _amountIn:", _amountIn);
        assertGe({ err: "///THEN _amountIn is greater than equal to 34", left: _amountIn, right: 34 });
    }

    function test_GetAmount1In_DoesNotRound() public view {
        uint256 _price = (2e18 * 1e6) / 1e6;
        uint256 _fee = 0;
        uint256 _amountOut = 110;
        (uint256 _amountIn, ) = pair.getAmount1In(_amountOut, _price, _fee);
        assertEq({ err: "///THEN _amountIn is equal to 55", left: _amountIn, right: 55 });
    }

    function test_GetAmount0In_RoundsUp() public view {
        uint256 _price = uint256(1e36) / ((3e18 * 1e6) / 1e6); // roughly 1/3
        uint256 _fee = 0;
        uint256 _amountOut = 100;
        (uint256 _amountIn, ) = pair.getAmount0In(_amountOut, _price, _fee);
        console.log("test_GetAmountIn_RoundsUp ~ _amountIn:", _amountIn);
        assertEq({ err: "///THEN _amountIn equal to 34", left: _amountIn, right: 34 });
    }

    function test_getAmount0In_DoesNotRound() public view {
        uint256 _price = uint256(1e36) / ((2e18 * 1e6) / 1e6); // roughly 1/2
        uint256 _fee = 0;
        uint256 _amountOut = 110;
        (uint256 _amountIn, ) = pair.getAmount0In(_amountOut, _price, _fee);
        assertEq({ err: "///THEN _amountIn is equal to 55", left: _amountIn, right: 55 });
    }
}
