// // SPDX-License-Identifier: ISC
// pragma solidity ^0.8.28;

// import "src/test/BaseTest.sol";

// /* solhint-disable func-name-mixedcase */
// contract TestPausePairs is BaseTest {
//     /// FEATURE: pause pairs

//     function setUp() public {
//         /// BACKGROUND:
//         _defaultSetup();

//         /// GIVEN: pauser is set to PAUSER_ROLE
//         assertTrue({
//             err: "/// GIVEN: pauser is set to PAUSER_ROLE on pair",
//             data: pair.hasRole(PAUSER_ROLE, pauserAddress)
//         });
//     }

//     function test_CanPausePair() public {
//         assertTrue({ err: "/// GIVEN: pair is unpaused (default)", data: pair.isPaused() == false });

//         /// WHEN: pauser calls setPaused with _isPaused = true
//         hoax(pauserAddress);
//         pair.setPaused(true);

//         assertTrue({ err: "/// THEN: Pair should be paused", data: pair.isPaused() == true });
//     }

//     function test_CannotPausePairIfNotPauser() public {
//         assertTrue({ err: "/// GIVEN: pair is unpaused (default)", data: pair.isPaused() == false });

//         /// WHEN: Unpriviledged caller calls setPaused with _isPaused = true
//         /// THEN: call reverts and pair is not paused
//         vm.expectRevert(abi.encodeWithSelector(AgoraAccessControl.AddressIsNotRole.selector, PAUSER_ROLE));
//         pair.setPaused(true);

//         assertTrue({ err: "/// THEN: Pair should remain unpaused", data: pair.isPaused() == false });
//     }

//     function test_CanUnpausePair() public {
//         hoax(pauserAddress);
//         pair.setPaused(true);
//         assertTrue({ err: "/// GIVEN: pair is paused", data: pair.isPaused() == true });

//         /// WHEN: pauser calls setPaused with _isPaused = false
//         hoax(pauserAddress);
//         pair.setPaused(false);

//         assertTrue({ err: "/// THEN: Pair should be unpaused", data: pair.isPaused() == false });
//     }

//     function test_CannotUnpausePairIfNotPauser() public {
//         hoax(pauserAddress);
//         pair.setPaused(true);
//         assertTrue({ err: "/// GIVEN: pair is paused", data: pair.isPaused() == true });

//         /// WHEN: Unpriviledged caller calls setPaused with _isPaused = false
//         /// THEN: call reverts and pair is not paused
//         vm.expectRevert(abi.encodeWithSelector(AgoraAccessControl.AddressIsNotRole.selector, PAUSER_ROLE));
//         pair.setPaused({ _setPaused: false });

//         assertTrue({ err: "/// THEN: Pair should remain paused", data: pair.isPaused() == true });
//     }
// }
