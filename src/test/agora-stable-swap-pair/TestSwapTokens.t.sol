// pragma solidity ^0.8.28;

// import "src/test/BaseTest.sol";

// contract TestSwapTokens is BaseTest {
//     /// FEATURE: pause pairs
//     address payable public bob = labelAndDeal("bob");
//     address payable public alice = labelAndDeal("alice");

//     function setUp() public {
//         /// BACKGROUND:
//         _defaultSetup();
//     }

//     //==============================================================================
//     // Testing Swap functions
//     //==============================================================================

//     function test_CanSwapToken0() public {
//         /// GIVEN: user has some token0
//         AddressAccountingSnapshot memory _initialAliceSnapshot = addressAccountingSnapshot(alice);
//         assertTrue({ err: "/// GIVEN: user has some token0", data: _initialAliceSnapshot.token0Balance > 0 });

//         /// WHEN: user calls swap with token0
//         hoax(alice);
//         pair.swap(_initialAliceSnapshot.token0Balance, 0, address(pair), "");

//         AddressAccountingSnapshot memory _finalAliceSnapshot = addressAccountingSnapshot(alice);
//         assertTrue({ err: "/// THEN: token0 balance should be 0", data: _finalAliceSnapshot.token0Balance == 0 });
//         assertTrue({
//             err: "/// THEN: user should have gotten token1",
//             data: _finalAliceSnapshot.token1Balance > _initialAliceSnapshot.token1Balance
//         });

//         DeltaAddressAccountingSnapshot memory _deltaAliceSnapshot = deltaAddressAccountingSnapshot(
//             _initialAliceSnapshot
//         );
//         uint256 _valueDelta = valueDeltaAddressAccountingSnapshot(_deltaAliceSnapshot);
//         console.log("/// THEN: the difference in value should be equal to the fee for token0", _valueDelta);
//         console.log("fees for token0", pair.token0PurchaseFee());

//         /// THEN: the difference in value should be equal to the feetoken0
//         /// THEN: reserves should have updated
//     }

//     function test_CanSwapToken1() public {
//         /// GIVEN: user has some token1
//         /// WHEN: user calls swapTokens with token1
//         /// THEN: user should have gotten token0
//         /// THEN: the difference in value should be equal to the feetoken1
//         /// THEN: reserves should have updated
//     }

//     // NOTE: does it make sense to test this?
//     function test_CannotSwapMoreThanReserves() public {
//         /// ! INFO: can I create a missmatch btw reserves internal and external accounting?
//         /// ! ^^ balance inflation attack
//         /// GIVEN: user has more token0 than reserves
//         /// WHEN: user calls swapTokens with token0
//         /// THEN: call reverts and user should not get token1
//         /// THEN: user should have the same amount of token0
//     }

//     function test_CannotSwapOnBothSides() public {
//         /// GIVEN: user has some token0 and token1
//         /// WHEN: user calls swapTokens with token0 and token1
//         /// THEN: call reverts with InvalidSWapAmounts
//     }

//     function test_SwapToken0ForExactToken1() public {
//         /// GIVEN: user has some token0
//         /// WHEN: user calls swapTokensForExactTokens with token0
//         /// THEN: user should have paid less or equal to amountInMax
//         /// THEN: user should have gotten the exact amount of token1
//     }

//     function test_SwapExactToken0ForToken1() public {
//         /// GIVEN: user has some token0
//         /// WHEN: user calls swapExactTokensForTokens with token0
//         /// THEN: user should have paid the exact amount of token1
//         /// THEN: user should have gotten more or equal to _amountOutMin
//     }

//     function test_SwapToken1ForExactToken0() public {
//         /// GIVEN: user has some token1
//         /// WHEN: user calls swapTokensForExactTokens with token1
//         /// THEN: user should have paid less or equal to amountInMax
//         /// THEN: user should have gotten the exact amount of token0
//     }

//     function test_SwapExactToken1ForToken0() public {
//         /// GIVEN: user has some token1
//         /// WHEN: user calls swapExactTokensForTokens with token1
//         /// THEN: user should have paid the exact amount of token0
//         /// THEN: user should have gotten more or equal to _amountOutMin
//     }

//     function test_fuzzGetAmount0Out() public {
//         /// GIVEN: user has some token1
//         /// WHEN: user calls _getAmounts0Out with token1
//         /// THEN: user should have gotten the exact amount of token0
//         /// THEN: the difference in value should be equal to the feetoken0
//     }

//     function test_fuzzGetAmount1Out() public {
//         /// GIVEN: user has some token0
//         /// WHEN: user calls _getAmounts1Out with token0
//         /// THEN: user should have gotten the exact amount of token1
//         /// THEN: the difference in value should be equal to the feetoken1
//     }

//     function test_fuzzGetAmount0In() public {
//         /// GIVEN: user has some token1
//         /// WHEN: user calls _getAmounts0In with token1
//         /// THEN: user should have gotten the exact amount of token0
//         /// THEN: the difference in value should be equal to the feetoken0
//     }

//     function test_fuzzGetAmount1In() public {
//         /// GIVEN: user has some token0
//         /// WHEN: user calls _getAmounts1In with token0
//         /// THEN: user should have gotten the exact amount of token1
//         /// THEN: the difference in value should be equal to the feetoken1
//     }

//     //==============================================================================
//     // Testing Reserves
//     //==============================================================================

//     function test_CanSwapAgainstEmptyReserves() public {
//         /// GIVEN: user has some token0
//         /// GIVEN: reserves for token0 are emtpy
//         /// GIVEN: reserves for token1 are above trade amount
//         /// WHEN: user calls swapTokens with token0
//         /// THEN: user should get token1
//     }

//     function test_CannotSwapTowardsEmptyReserves() public {
//         /// GIVEN: user has some token0
//         /// GIVEN: reserves for token1 are emtpy
//         /// GIVEN: reserves for token0 are above trade amount
//         /// WHEN: user calls swapTokens with token0
//         /// THEN: call reverts with InsufficientLiquidity
//     }

//     function test_ReservesUpdateProperly() public {
//         /// GIVEN: user has some token0
//         /// WHEN: user calls swapTokens with token0
//         /// THEN: user should have get token1
//         /// THEN: reserves should have updated
//     }
// }
