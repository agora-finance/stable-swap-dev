// // SPDX-License-Identifier: ISC
// pragma solidity ^0.8.28;

// import "src/test/BaseTest.sol";

// /* solhint-disable func-name-mixedcase */
// contract TestSetFees is BaseTest {
//     /// FEATURE: set fees for pairs

//     function setUp() public {
//         /// BACKGROUND:
//         _defaultSetup();

//         assertTrue({
//             err: "/// GIVEN: feeSetter has privileges over the pair",
//             data: pair.hasRole(FEE_SETTER_ROLE, feeSetterAddress)
//         });
//     }

//     function authorizedSetFeeBounds(
//         uint256 _minToken0PurchaseFee,
//         uint256 _maxToken0PurchaseFee,
//         uint256 _minToken1PurchaseFee,
//         uint256 _maxToken1PurchaseFee
//     ) internal {
//         hoax(adminAddress);
//         pair.setFeeBounds(_minToken0PurchaseFee, _maxToken0PurchaseFee, _minToken1PurchaseFee, _maxToken1PurchaseFee);
//     }

//     function test_CanSetToken0Fees() public {
//         address _token0 = pair.token0();
//         assertTrue({ err: "/// GIVEN: token0PurchaseFee is not 1e16 (0.01)", data: pair.token0PurchaseFee() != 1e16 });

//         /// WHEN: privileged caller calls setFeeBounds for token0 [0 - 0.02]
//         authorizedSetFeeBounds({
//             _minToken0PurchaseFee: 0,
//             _maxToken0PurchaseFee: 2e16, // 0.02
//             _minToken1PurchaseFee: 0,
//             _maxToken1PurchaseFee: 0
//         });

//         /// WHEN: privileged caller calls setToken0Fee with _fee = 1e16 0.01
//         hoax(feeSetterAddress);
//         pair.setTokenPurchaseFees(1e16, 0);

//         assertTrue({
//             err: "/// THEN: token0PurchaseFee is set to 1e16 (0.01)",
//             data: pair.token0PurchaseFee() == 1e16
//         });
//     }

//     function test_CannotSetToken0FeesIfNotFeeSetter() public {
//         address _token0 = pair.token0();

//         /// WHEN: privileged caller calls setFeeBounds for token0 [0 - 0.02]
//         authorizedSetFeeBounds({
//             _minToken0PurchaseFee: 0,
//             _maxToken0PurchaseFee: 2e16, // 0.02
//             _minToken1PurchaseFee: 0,
//             _maxToken1PurchaseFee: 0
//         });

//         /// GIVEN: token0PurchaseFee is 1e16 (0.01)
//         hoax(feeSetterAddress);
//         pair.setTokenPurchaseFees(_token0, 1e16);

//         assertTrue({ err: "/// GIVEN: token0PurchaseFee is 1e16 (0.01)", data: pair.token0PurchaseFee() == 1e16 });

//         /// WHEN: unpriviledged caller calls setToken0Fee with _fee = 5e16 (0.05)
//         vm.expectRevert(abi.encodeWithSelector(AgoraAccessControl.AddressIsNotRole.selector, FEE_SETTER_ROLE));
//         pair.setTokenPurchaseFees(_token0, 5e16);
//         /// THEN: call reverts and fee remains unchanged
//     }

//     function test_CanSetToken1Fees() public {
//         address _token1 = pair.token1();
//         assertTrue({ err: "/// GIVEN: token1PurchaseFee is not 1e16 (0.01)", data: pair.token1PurchaseFee() != 1e16 });

//         /// WHEN: privileged caller calls setFeeBounds for token1 [0 - 0.02]
//         authorizedSetFeeBounds({
//             _minToken0PurchaseFee: 0,
//             _maxToken0PurchaseFee: 0,
//             _minToken1PurchaseFee: 0,
//             _maxToken1PurchaseFee: 2e16 // 0.02
//         });

//         /// WHEN: privileged caller calls setToken1Fee with _fee = 1e16 (0.01)
//         hoax(feeSetterAddress);
//         pair.setTokenPurchaseFees(_token1, 1e16);

//         assertTrue({
//             err: "/// THEN: token1PurchaseFee is set to 1e16 (0.01)",
//             data: pair.token1PurchaseFee() == 1e16
//         });
//     }

//     function test_CannotSetToken1FeesIfNotFeeSetter() public {
//         /// GIVEN: token1PurchaseFee is 1e16 (0.01)
//         address _token1 = pair.token1();

//         /// WHEN: privileged caller calls setFeeBounds for token1 [0 - 0.02]
//         authorizedSetFeeBounds({
//             _minToken0PurchaseFee: 0,
//             _maxToken0PurchaseFee: 0,
//             _minToken1PurchaseFee: 0,
//             _maxToken1PurchaseFee: 2e16 // 0.02
//         });

//         hoax(feeSetterAddress);
//         pair.setTokenPurchaseFees(_token1, 1e16);
//         assertTrue({ err: "/// GIVEN: token1PurchaseFee is 1e16 (0.01)", data: pair.token1PurchaseFee() == 1e16 });

//         /// THEN: call reverts and fee remains unchanged
//         vm.expectRevert(abi.encodeWithSelector(AgoraAccessControl.AddressIsNotRole.selector, FEE_SETTER_ROLE));
//         /// WHEN: unpriviledged caller calls setToken1Fee with _fee = 5e16 (0.05)
//         pair.setTokenPurchaseFees(_token1, 5e16);

//         assertTrue({ err: "/// THEN: fee remains unchanged", data: pair.token1PurchaseFee() == 1e16 });
//     }

//     function test_CannotSetInvalidToken0PurchaseFee() public {
//         address _token0 = pair.token0();
//         assertTrue({ err: "/// GIVEN: token0PurchaseFee is not 1e16 (0.01)", data: pair.token0PurchaseFee() != 1e16 });

//         /// WHEN: privileged caller calls setFeeBounds for token0 [0 - 0]
//         authorizedSetFeeBounds({
//             _minToken0PurchaseFee: 0,
//             _maxToken0PurchaseFee: 0,
//             _minToken1PurchaseFee: 0,
//             _maxToken1PurchaseFee: 0
//         });

//         /// THEN: call reverts because of out of bounds fee
//         vm.expectRevert(abi.encodeWithSelector(AgoraStableSwapPairCore.InvalidTokenPurchaseFee.selector, _token0));
//         /// WHEN: privileged caller calls setToken0Fee with _fee = 1e16 0.01
//         hoax(feeSetterAddress);
//         pair.setTokenPurchaseFees(_token0, 1e16);
//     }

//     function test_CannotSetInvalidToken1PurchaseFee() public {
//         address _token1 = pair.token1();
//         assertTrue({ err: "/// GIVEN: token1PurchaseFee is not 1e16 (0.01)", data: pair.token1PurchaseFee() != 1e16 });

//         /// WHEN: privileged caller calls setFeeBounds for token1 [0 - 0]
//         authorizedSetFeeBounds({
//             _minToken0PurchaseFee: 0,
//             _maxToken0PurchaseFee: 0,
//             _minToken1PurchaseFee: 0,
//             _maxToken1PurchaseFee: 0
//         });

//         /// THEN: call reverts because of out of bounds fee
//         vm.expectRevert(abi.encodeWithSelector(AgoraStableSwapPairCore.InvalidTokenPurchaseFee.selector, _token1));
//         /// WHEN: privileged caller calls setToken1Fee with _fee = 1e16 0.01
//         hoax(feeSetterAddress);
//         pair.setTokenPurchaseFees(_token1, 1e16);
//     }
// }
