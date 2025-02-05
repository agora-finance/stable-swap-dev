// SPDX-License-Identifier: ISC
pragma solidity ^0.8.28;

import "src/test/BaseTest.sol";

/* solhint-disable func-name-mixedcase */
contract TestSetFeeReceiver is BaseTest {
    /// FEATURE: set fee receiver for pairs

    address payable public newFeeReceiver;

    function setUp() public {
        /// BACKGROUND:
        _defaultSetup();

        newFeeReceiver = labelAndDeal("newFeeReceiver");

        assertTrue({
            err: "/// GIVEN: admin has privileges over the pair",
            data: pair.hasRole(ADMIN_ROLE, adminAddress)
        });
    }

    function test_CanSetFeeReceiver() public {
        address currentFeeReceiver = pair.feeReceiverAddress();
        assertTrue({
            err: "/// GIVEN: newFeeReceiver is different from current fee receiver",
            data: currentFeeReceiver != newFeeReceiver
        });

        /// WHEN: admin calls setFeeReceiver with new address
        hoax(adminAddress);
        pair.setFeeReceiver(newFeeReceiver);

        /// THEN: fee receiver should be updated
        assertTrue({
            err: "/// THEN: fee receiver should be updated to new address",
            data: pair.feeReceiverAddress() == newFeeReceiver
        });
    }

    function test_CanSetFeeReceiverToSameAddress() public {
        address currentFeeReceiver = pair.feeReceiverAddress();

        /// WHEN: admin calls setFeeReceiver with same address
        hoax(adminAddress);
        pair.setFeeReceiver(currentFeeReceiver);

        /// THEN: fee receiver should remain the same
        assertTrue({
            err: "/// THEN: fee receiver should remain unchanged",
            data: pair.feeReceiverAddress() == currentFeeReceiver
        });
    }

    function test_CannotSetFeeReceiverIfNotAdmin() public {
        /// WHEN: non-admin tries to set fee receiver
        /// THEN: function should revert
        vm.expectRevert(abi.encodeWithSelector(AgoraAccessControl.AddressIsNotRole.selector, ADMIN_ROLE));
        pair.setFeeReceiver(newFeeReceiver);
    }

    function test_CanSetFeeReceiverToZeroAddress() public {
        address currentFeeReceiver = pair.feeReceiverAddress();
        assertTrue({
            err: "/// GIVEN: current fee receiver is not zero address",
            data: currentFeeReceiver != address(0)
        });

        /// WHEN: admin calls setFeeReceiver with zero address
        hoax(adminAddress);
        pair.setFeeReceiver(address(0));

        /// THEN: fee receiver should be updated to zero address
        assertTrue({
            err: "/// THEN: fee receiver should be zero address",
            data: pair.feeReceiverAddress() == address(0)
        });
    }
}
