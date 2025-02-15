pragma solidity ^0.8.28;

import "src/test/BaseTest.sol";

contract TestSwapTokens is BaseTest {
    using ArrayHelper for address[];

    /// FEATURE: pause pairs
    address payable public bob = labelAndDeal("bob");
    address payable public alice = labelAndDeal("alice");

    address token0Address;
    address token1Address;

    IERC20 token0;
    IERC20 token1;

    function setUp() public {
        /// BACKGROUND:
        _defaultSetup();

        token0Address = pair.token0();
        token1Address = pair.token1();

        token0 = IERC20(token0Address);
        token1 = IERC20(token1Address);

        _seedErc20({ _tokenAddress: token0Address, _to: bob, _amount: 1e6 * 1e18 });
        _seedErc20({ _tokenAddress: token1Address, _to: bob, _amount: 1e6 * 1e18 });
        _seedErc20({ _tokenAddress: token0Address, _to: alice, _amount: 1e6 * 1e18 });
        _seedErc20({ _tokenAddress: token1Address, _to: alice, _amount: 1e18 });

        hoax(bob);
        token0.approve(address(pair), type(uint256).max);
        token1.approve(address(pair), type(uint256).max);

        hoax(alice);
        token0.approve(address(pair), type(uint256).max);
        token1.approve(address(pair), type(uint256).max);

        _setApprovedSwapperAsWhitelister({ _pair: pair, _newSwapper: alice });
        _setApprovedSwapperAsWhitelister({ _pair: pair, _newSwapper: bob });
    }

    //==============================================================================
    // Testing Swap functions
    //==============================================================================

    function test_CanSwapToken0() public {
        AddressAccountingSnapshot memory _initialAliceSnapshot = addressAccountingSnapshot(alice);
        assertTrue({ err: "/// GIVEN: user has some token0", data: _initialAliceSnapshot.token0Balance > 0 });

        /// WHEN: user calls swap with token0
        startHoax(alice);
        token0.transfer(address(pair), 1e18);
        pair.swap(0, 1, alice, "");

        AddressAccountingSnapshot memory _finalAliceSnapshot = addressAccountingSnapshot(alice);
        assertTrue({
            err: "/// THEN: user should have gotten token1",
            data: _finalAliceSnapshot.token1Balance > _initialAliceSnapshot.token1Balance
        });

        DeltaAddressAccountingSnapshot memory _deltaAliceSnapshot = deltaAddressAccountingSnapshot(
            _initialAliceSnapshot
        );
        uint256 _valueDelta = valueDeltaAddressAccountingSnapshot(_deltaAliceSnapshot);
        console.log("/// THEN: the difference in value should be equal to the fee for token0", _valueDelta);
        console.log("fees for token0", pair.token0PurchaseFee());

        /// THEN: the difference in value should be equal to the feetoken0
        /// THEN: reserves should have updated
    }

    function test_CannotStealTokens() public {
        pair.sync();
        /// GIVEN: balance of tokens matches reserves of tokens + accumulated fees
        assertEq(IERC20(token0Address).balanceOf(pairAddress), pair.reserve0() + pair.token0FeesAccumulated());
        assertEq(IERC20(token1Address).balanceOf(pairAddress), pair.reserve1() + pair.token1FeesAccumulated());

        // WHEN: @approveSwapperAddress calls swap without sending any tokens in
        vm.expectRevert(abi.encodeWithSelector(AgoraStableSwapPairCore.InsufficientInputAmount.selector));
        pair.swap({
            _amount0Out: 0,
            _amount1Out: 1e18, //@approveSwapperAddress can transfer token1 out without sending any token0 in
            _to: address(this),
            _data: new bytes(0)
        });

        /// THEN: expect revert
    }

    function test_CanSwapToken1() public {
        /// GIVEN: user has some token1
        /// WHEN: user calls swapTokens with token1
        /// THEN: user should have gotten token0
        /// THEN: the difference in value should be equal to the feetoken1
        /// THEN: reserves should have updated
    }

    // NOTE: does it make sense to test this?
    function test_CannotSwapMoreThanReserves() public {
        /// GIVEN: pair has 1e18 token1
        assertEq(token1.balanceOf(pairAddress), 1e18);

        /// WHEN: user calls swapTokensForExactTokens() requesting 2e18 token1
        vm.expectRevert(abi.encodeWithSelector(AgoraStableSwapPairCore.InsufficientLiquidity.selector));
        hoax(alice);
        pair.swapTokensForExactTokens(
            2e18,
            type(uint256).max,
            new address[](0).concat(token0Address).concat(token1Address),
            alice,
            block.timestamp + 100
        );

        /// THEN: call reverts and user should not get token1
    }

    function test_CannotSwapOnBothSides() public {
        /// GIVEN: user has some token0 and token1
        /// WHEN: user calls swapTokens with token0 and token1
        /// THEN: call reverts with InvalidSWapAmounts
    }

    function test_SwapToken0ForExactToken1() public {
        /// GIVEN: user has some token0
        /// WHEN: user calls swapTokensForExactTokens with token0
        /// THEN: user should have paid less or equal to amountInMax
        /// THEN: user should have gotten the exact amount of token1
    }

    function test_SwapExactToken0ForToken1() public {
        /// GIVEN: user has some token0
        /// WHEN: user calls swapExactTokensForTokens with token0
        /// THEN: user should have paid the exact amount of token1
        /// THEN: user should have gotten more or equal to _amountOutMin
    }

    function test_SwapToken1ForExactToken0() public {
        /// GIVEN: user has some token1
        /// WHEN: user calls swapTokensForExactTokens with token1
        /// THEN: user should have paid less or equal to amountInMax
        /// THEN: user should have gotten the exact amount of token0
    }

    function test_SwapExactToken1ForToken0() public {
        /// GIVEN: user has some token1
        /// WHEN: user calls swapExactTokensForTokens with token1
        /// THEN: user should have paid the exact amount of token0
        /// THEN: user should have gotten more or equal to _amountOutMin
    }

    function test_fuzzGetAmount0Out() public {
        /// GIVEN: user has some token1
        /// WHEN: user calls _getAmounts0Out with token1
        /// THEN: user should have gotten the exact amount of token0
        /// THEN: the difference in value should be equal to the feetoken0
    }

    function test_fuzzGetAmount1Out() public {
        /// GIVEN: user has some token0
        /// WHEN: user calls _getAmounts1Out with token0
        /// THEN: user should have gotten the exact amount of token1
        /// THEN: the difference in value should be equal to the feetoken1
    }

    function test_fuzzGetAmount0In() public {
        /// GIVEN: user has some token1
        /// WHEN: user calls _getAmounts0In with token1
        /// THEN: user should have gotten the exact amount of token0
        /// THEN: the difference in value should be equal to the feetoken0
    }

    function test_fuzzGetAmount1In() public {
        /// GIVEN: user has some token0
        /// WHEN: user calls _getAmounts1In with token0
        /// THEN: user should have gotten the exact amount of token1
        /// THEN: the difference in value should be equal to the feetoken1
    }

    //==============================================================================
    // Testing Reserves
    //==============================================================================

    function test_CanSwapAgainstEmptyReserves() public {
        /// GIVEN: user has some token0
        /// GIVEN: reserves for token0 are emtpy
        /// GIVEN: reserves for token1 are above trade amount
        /// WHEN: user calls swapTokens with token0
        /// THEN: user should get token1
    }

    function test_CannotSwapTowardsEmptyReserves() public {
        /// GIVEN: user has some token0
        /// GIVEN: reserves for token1 are emtpy
        /// GIVEN: reserves for token0 are above trade amount
        /// WHEN: user calls swapTokens with token0
        /// THEN: call reverts with InsufficientLiquidity
    }

    function test_ReservesUpdateProperly() public {
        /// GIVEN: user has some token0
        /// WHEN: user calls swapTokens with token0
        /// THEN: user should have get token1
        /// THEN: reserves should have updated
    }
}
