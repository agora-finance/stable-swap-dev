// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "../BaseTest.sol";

contract TestSwap is BaseTest {
    using ArrayHelper for *;
    /// FEATURE: Swap functionality

    address payable public bob = labelAndDeal("bob");
    address payable public alice = labelAndDeal("alice");

    function setUp() public virtual {
        /// BACKGROUND:
        _defaultSetup();
    }

    function test_flow() public {
        /// Price is 2AUSD per weth and interest is 5% yearly
        _configureOraclePriceAsPriceSetter({
            _pair: pair,
            _basePrice: (2.1e18 * 1e6) / 1e18,
            _annualizedInterestRate: 5e16
        });

        // setFees
        _setFeesAsFeeSetter({
            _pair: pair,
            _token0PurchaseFee: 1e16, // 1%
            _token1PurchaseFee: 1e16 // 1%
        });

        uint256 _price = pair.getPrice();
        console.log("test_flow ~ _price:", _price);

        // purchase token0
        pair.sync();
        _seedErc20({ _tokenAddress: pair.token0(), _to: address(this), _amount: 1e18 });
        _seedErc20({ _tokenAddress: pair.token1(), _to: address(this), _amount: 1e18 });
        IERC20(pair.token0()).approve(address(pair), 1e18);
        IERC20(pair.token1()).approve(address(pair), 1e18);
        uint256[] memory _amounts = pair.swapTokensForExactTokens({
            _amountOut: 1e6,
            _amountInMax: 1e40,
            _path: (new address[](0).concat(pair.token1())).concat(pair.token0()),
            _to: address(this),
            _deadline: block.timestamp + 100
        });

        console.log("test_flow ~ _amounts[0]:", _amounts[0]);
        console.log("test_flow ~ _amounts[1]:", _amounts[1]);
    }
}
