// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "../BaseTest.sol";

contract TestCalculatePrice is BaseTest {
    /// FEATURE: GetPrice

    address payable public bob = labelAndDeal("bob");
    address payable public alice = labelAndDeal("alice");

    function setUp() public {
        /// BACKGROUND:
        _defaultSetup();
    }

    function test_calculatePriceWithPositiveRate() public view {
        uint256 _price = 2e18;
        uint256 _lastUpdated = 0;
        uint256 _now = 365 days;
        int256 _perSecondInterestRate = int256(5e16) / 365 days;
        uint256 _result = pair.calculatePrice(_lastUpdated, _now, _perSecondInterestRate, _price);
        assertApproxEqRelDecimal({
            err: "///THEN _result is equal to 2.1e18",
            left: _result,
            right: 2.1e18,
            maxPercentDelta: 1e15,
            decimals: 18
        });
    }

    function test_calculatePriceWithNegativeRate() public view {
        uint256 _price = 2e18;
        uint256 _lastUpdated = 0;
        uint256 _now = 365 days;
        int256 _perSecondInterestRate = int256(-5e16) / 365 days;
        uint256 _result = pair.calculatePrice(_lastUpdated, _now, _perSecondInterestRate, _price);
        console.log("test_calculatePrice ~ _result:", _result);
    }

    function test_ffi() public {
        uint256 _price = 2e18;
        uint256 _lastUpdated = 0;
        uint256 _now = 365 days;
        int256 _perSecondInterestRate = int256(5e16) / 365 days;
        uint256 _result = _calculatePriceWithFfi(_lastUpdated, _now, _perSecondInterestRate, _price);
        assertApproxEqRelDecimal({
            err: "///THEN _result is equal to 2.1e18",
            left: _result,
            right: 2.1e18,
            maxPercentDelta: 1e15,
            decimals: 18
        });
    }
}
