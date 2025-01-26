// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "../BaseTest.sol";

contract TestGetprice is BaseTest {
    /// FEATURE: getPrice + getPriceNormalized

    address payable public bob = labelAndDeal("bob");
    address payable public alice = labelAndDeal("alice");

    function setUp() public {
        /// BACKGROUND:
        _defaultSetup();
    }

    function test_getPrice() public view {
        PairStateSnapshot memory _initialState = pairStateSnapshot();

        /// GIVEN: basePrice is 2e18
        assertEq(_initialState.basePrice, 2e18);

        /// GIVEN: lastUpdated = block.timestamp
        assertEq(_initialState.priceLastUpdated, block.timestamp);

        /// WHEN calling getPrice();
        uint256 _result = pair.getPrice();

        assertEq({ err: "/// THEN: _result is equal to 2e18", left: _result, right: 2e18 });
    }

    function test_FuzzCalculatePrice(
        uint40 _lastUpdated,
        uint16 _now,
        int32 _perSecondInterestRate,
        uint112 _price
    ) public {
        uint256 _currentTimestamp = uint256(_lastUpdated) + _now;
        console.log("test_FuzzCalculatePrice ~ _currentTimestamp:", _currentTimestamp);
        uint256 _result = pair.calculatePrice(_lastUpdated, _currentTimestamp, _perSecondInterestRate, _price);
        uint256 _expected = _calculatePriceWithFfi(_lastUpdated, _currentTimestamp, _perSecondInterestRate, _price);
        assertApproxEqRelDecimal({
            err: "///THEN _result is equal to 2.1e18",
            left: _expected,
            right: _result,
            maxPercentDelta: 1e10,
            decimals: 18
        });
    }
}
