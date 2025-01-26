// SPDX-License-Identifier: ISC
pragma solidity ^0.8.28;

import "src/test/BaseTest.sol";

/* solhint-disable func-name-mixedcase */
contract SetterFunctions is BaseTest {
    function given_adminAssignsRole(string memory _role, address _address) public {
        hoax(adminAddress);
        pair.assignRole(_role, _address, true);
    }
}

contract TestSetters is BaseTest, SetterFunctions {
    /// FEATURE: Configuration setters
    address payable public bob;
    address payable public alice;

    function setUp() public {
        /// BACKGROUND:
        _defaultSetup();

        bob = labelAndDeal("bob");
        alice = labelAndDeal("alice");

        /// GIVEN: admin is set to ADMIN_ROLE
        assertTrue({
            err: "/// GIVEN: admin is set to ADMIN_ROLE on pair",
            data: pair.hasRole(ADMIN_ROLE, adminAddress)
        });
    }

    function test_CanSetApprovedSwapper() public {
        /// GIVEN: whitelisterAddress has the WHITELISTER_ROLE
        assertTrue({
            err: "/// GIVEN: whitelisterAddress has the WHITELISTER_ROLE",
            data: pair.hasRole(WHITELISTER_ROLE, whitelisterAddress)
        });

        /// WHEN: whitelister assigns the approvedSwapper role to alice
        hoax(whitelisterAddress);
        pair.setApprovedSwapper(alice, true);

        assertTrue({
            err: "///THEN: alice should be an approved swapper",
            data: pair.hasRole(APPROVED_SWAPPER, alice)
        });
    }

    function test_CannotSetApprovedSwapperIfNotWhitelister() public {
        /// GIVEN: Alice is not an approved swapper
        assertFalse({
            err: "/// GIVEN: alice is not an approved swapper",
            data: pair.hasRole(APPROVED_SWAPPER, alice)
        });

        vm.expectRevert(abi.encodeWithSelector(AgoraAccessControl.AddressIsNotRole.selector, WHITELISTER_ROLE));
        /// WHEN: approvedSwapper is set to alice
        pair.setApprovedSwapper(alice, true);
        /// THEN: approvedSwapper reverts when set to alice
        assertFalse(pair.hasRole(APPROVED_SWAPPER, alice), "/// THEN: approvedSwapper is not set to alice");
    }

    function test_CanSetFeeSetter() public {
        /// WHEN: admin sets feeSetter role to alice
        hoax(adminAddress);
        pair.assignRole(FEE_SETTER_ROLE, alice, true);

        assertTrue({
            err: "/// THEN: alice should have the feeSetter role",
            data: pair.hasRole(FEE_SETTER_ROLE, alice)
        });
    }

    function test_CannotSetFeeSetterIfNotAdmin() public {
        /// GIVEN: alice is not a fee setter
        assertFalse({ err: "/// GIVEN: alice is not a fee setter", data: pair.hasRole(FEE_SETTER_ROLE, alice) });

        vm.expectRevert(abi.encodeWithSelector(AgoraAccessControl.AddressIsNotRole.selector, ADMIN_ROLE));
        /// WHEN: feeSetter is set to alice
        pair.assignRole(FEE_SETTER_ROLE, alice, true);

        assertFalse({ err: "/// THEN: alice is not a fee setter", data: pair.hasRole(FEE_SETTER_ROLE, alice) });
    }

    function test_CanSetTokenRemover() public {
        /// WHEN: admin assigns the tokenRemover role to alice
        hoax(adminAddress);
        pair.assignRole(TOKEN_REMOVER_ROLE, alice, true);

        assertTrue({
            err: "/// THEN: alice should have the tokenRemover role",
            data: pair.hasRole(TOKEN_REMOVER_ROLE, alice)
        });
    }

    function test_CannotSetTokenRemoverIfNotAdmin() public {
        /// GIVEN: alice is not a token remover
        assertFalse({ err: "/// GIVEN: alice is not a token remover", data: pair.hasRole(TOKEN_REMOVER_ROLE, alice) });

        /// WHEN: feeSetter is set to alice
        /// THEN: call reverts and alice is not a token remover
        vm.expectRevert(abi.encodeWithSelector(AgoraAccessControl.AddressIsNotRole.selector, ADMIN_ROLE));
        pair.assignRole(TOKEN_REMOVER_ROLE, alice, true);
    }

    function test_CanSetPauser() public {
        /// WHEN: admin assigns the pauser role to alice
        hoax(adminAddress);
        pair.assignRole(PAUSER_ROLE, alice, true);

        assertTrue({ err: "/// THEN: alice is pauser role ", data: pair.hasRole(PAUSER_ROLE, alice) });
    }

    function test_CannotSetPauserIfNotAdmin() public {
        /// GIVEN: alice is not a pauser
        assertFalse({ err: "/// GIVEN: alice is not a pauser", data: pair.hasRole(PAUSER_ROLE, alice) });

        vm.expectRevert(abi.encodeWithSelector(AgoraAccessControl.AddressIsNotRole.selector, ADMIN_ROLE));
        /// WHEN: pauser is set to alice
        pair.assignRole(PAUSER_ROLE, alice, true);

        assertFalse({ err: "/// THEN: pauser is not set to alice", data: pair.hasRole(PAUSER_ROLE, alice) });
    }
}
