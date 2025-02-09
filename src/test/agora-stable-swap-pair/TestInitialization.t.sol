// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "../BaseTest.sol";

contract TestInitialization is BaseTest {
    /// FEATURE: initialization of the pair

    function test_initialize() public {
        AgoraStableSwapPairParams memory _agoraStableSwapPairParams = _defaultSetup();

        // THEN: All values should be properly set
        assertEq(pair.token0(), _agoraStableSwapPairParams.token0, "///THEN: token0 should be set in storage");
        assertEq(
            pair.token0Decimals(),
            _agoraStableSwapPairParams.token0Decimals,
            "///THEN: token0 decimals should be set in storage"
        );
        assertEq(pair.token1(), _agoraStableSwapPairParams.token1, "///THEN: token1 should be set in storage");
        assertEq(
            pair.token1Decimals(),
            _agoraStableSwapPairParams.token1Decimals,
            "///THEN: token1 decimals should be set in storage"
        );
        assertEq(
            pair.minToken0PurchaseFee(),
            _agoraStableSwapPairParams.minToken0PurchaseFee,
            "///THEN: min token0 purchase fee should be set in storage"
        );
        assertEq(
            pair.maxToken0PurchaseFee(),
            _agoraStableSwapPairParams.maxToken0PurchaseFee,
            "///THEN: max token0 purchase fee should be set in storage"
        );
        assertEq(
            pair.minToken1PurchaseFee(),
            _agoraStableSwapPairParams.minToken1PurchaseFee,
            "///THEN: min token1 purchase fee should be set in storage"
        );
        assertEq(
            pair.maxToken1PurchaseFee(),
            _agoraStableSwapPairParams.maxToken1PurchaseFee,
            "///THEN: max token1 purchase fee should be set in storage"
        );
        assertEq(
            pair.token0PurchaseFee(),
            _agoraStableSwapPairParams.token0PurchaseFee,
            "///THEN: token0 purchase fee should be set in storage"
        );
        assertEq(
            pair.token1PurchaseFee(),
            _agoraStableSwapPairParams.token1PurchaseFee,
            "///THEN: token1 purchase fee should be set in storage"
        );
        assertEq(
            pair.tokenReceiverAddress(),
            _agoraStableSwapPairParams.initialTokenReceiver,
            "///THEN: token receiver address should be set in storage"
        );
        assertEq(
            pair.feeReceiverAddress(),
            _agoraStableSwapPairParams.initialFeeReceiver,
            "///THEN: fee receiver address should be set in storage"
        );
        assertEq(
            pair.minBasePrice(),
            _agoraStableSwapPairParams.minBasePrice,
            "///THEN: min base price should be set in storage"
        );
        assertEq(
            pair.maxBasePrice(),
            _agoraStableSwapPairParams.maxBasePrice,
            "///THEN: max base price should be set in storage"
        );
        assertEq(
            pair.minAnnualizedInterestRate(),
            _agoraStableSwapPairParams.minAnnualizedInterestRate,
            "///THEN: min annualized interest rate should be set in storage"
        );
        assertEq(
            pair.maxAnnualizedInterestRate(),
            _agoraStableSwapPairParams.maxAnnualizedInterestRate,
            "///THEN: max annualized interest rate should be set in storage"
        );
        assertEq(
            pair.basePrice(),
            _agoraStableSwapPairParams.basePrice,
            "///THEN: base price should be set in storage"
        );
        assertEq(
            pair.perSecondInterestRate(),
            _agoraStableSwapPairParams.annualizedInterestRate / 365 days,
            "///THEN: per second interest rate should be set in storage"
        );
        assertEq(pair.priceLastUpdated(), block.timestamp, "///THEN: price last updated should be set in storage");
        assertEq(pair.isPaused(), false, "///THEN: pair should not be paused");

        // THEN: All roles should be properly assigned AND only have one address for each role
        assertTrue(
            pair.hasRole(ADMIN_ROLE, _agoraStableSwapPairParams.initialAdminAddress),
            "///THEN: admin role should be set in storage"
        );
        assertEq(pair.getRoleMembers(ADMIN_ROLE).length, 1, "///THEN: admin role should have one address");
        assertEq(
            pair.getRoleMembers(ADMIN_ROLE)[0],
            _agoraStableSwapPairParams.initialAdminAddress,
            "///THEN: admin role should have the correct address"
        );

        assertTrue(
            pair.hasRole(WHITELISTER_ROLE, _agoraStableSwapPairParams.initialWhitelister),
            "///THEN: whitelister role should be set in storage"
        );
        assertEq(pair.getRoleMembers(WHITELISTER_ROLE).length, 1, "///THEN: whitelister role should have one address");
        assertEq(
            pair.getRoleMembers(WHITELISTER_ROLE)[0],
            _agoraStableSwapPairParams.initialWhitelister,
            "///THEN: whitelister role should have the correct address"
        );

        assertTrue(
            pair.hasRole(FEE_SETTER_ROLE, _agoraStableSwapPairParams.initialFeeSetter),
            "///THEN: fee setter role should be set in storage"
        );
        assertEq(pair.getRoleMembers(FEE_SETTER_ROLE).length, 1, "///THEN: fee setter role should have one address");
        assertEq(
            pair.getRoleMembers(FEE_SETTER_ROLE)[0],
            _agoraStableSwapPairParams.initialFeeSetter,
            "///THEN: fee setter role should have the correct address"
        );

        assertTrue(
            pair.hasRole(TOKEN_REMOVER_ROLE, _agoraStableSwapPairParams.initialTokenRemover),
            "///THEN: token remover role should be set in storage"
        );
        assertEq(
            pair.getRoleMembers(TOKEN_REMOVER_ROLE).length,
            1,
            "///THEN: token remover role should have one address"
        );
        assertEq(
            pair.getRoleMembers(TOKEN_REMOVER_ROLE)[0],
            _agoraStableSwapPairParams.initialTokenRemover,
            "///THEN: token remover role should have the correct address"
        );

        assertTrue(
            pair.hasRole(PAUSER_ROLE, _agoraStableSwapPairParams.initialPauser),
            "///THEN: pauser role should be set in storage"
        );
        assertEq(pair.getRoleMembers(PAUSER_ROLE).length, 1, "///THEN: pauser role should have one address");
        assertEq(
            pair.getRoleMembers(PAUSER_ROLE)[0],
            _agoraStableSwapPairParams.initialPauser,
            "///THEN: pauser role should have the correct address"
        );

        assertTrue(
            pair.hasRole(PRICE_SETTER_ROLE, _agoraStableSwapPairParams.initialPriceSetter),
            "///THEN: price setter role should be set in storage"
        );
        assertEq(
            pair.getRoleMembers(PRICE_SETTER_ROLE).length,
            1,
            "///THEN: price setter role should have one address"
        );
        assertEq(
            pair.getRoleMembers(PRICE_SETTER_ROLE)[0],
            _agoraStableSwapPairParams.initialPriceSetter,
            "///THEN: price setter role should have the correct address"
        );
    }
}
