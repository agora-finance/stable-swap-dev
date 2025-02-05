// SPDX-License-Identifier: ISC
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "src/test/BaseTest.sol";

/* solhint-disable func-name-mixedcase */
contract TestRemoveTokens is BaseTest {
    /// FEATURE: Remove tokens from the pair

    address public nonReserveToken;
    uint256 public constant INITIAL_BALANCE = 1000e18;
    uint256 public constant REMOVAL_AMOUNT = 100e18;

    function setUp() public {
        /// BACKGROUND:
        _defaultSetup();

        // Deploy a non-reserve token for testing
        nonReserveToken = address(new MockERC20("Non Reserve Token", "NRT", 18));
        deal(nonReserveToken, address(pair), INITIAL_BALANCE);

        assertTrue({
            err: "/// GIVEN: tokenRemover has privileges over the pair",
            data: pair.hasRole(TOKEN_REMOVER_ROLE, tokenRemoverAddress)
        });
    }

    function test_CanRemoveToken0() public {
        address _token0 = pair.token0();
        uint256 _initialTokenBalance = IERC20(_token0).balanceOf(address(pair));
        uint256 _initialToken0FeesAccumulated = pair.token0FeesAccumulated();
        address _tokenReceiver = pair.tokenReceiverAddress();

        assertTrue({
            err: "/// GIVEN: token0 balance is greater than the removal amount",
            data: _initialTokenBalance > REMOVAL_AMOUNT
        });

        /// WHEN: tokenRemover calls removeTokens with token0
        hoax(tokenRemoverAddress);
        pair.removeTokens(_token0, REMOVAL_AMOUNT);

        /// THEN: token balance should decrease by removal amount
        assertEq(
            IERC20(_token0).balanceOf(address(pair)),
            _initialTokenBalance - REMOVAL_AMOUNT,
            "Token balance should decrease by removal amount"
        );

        /// THEN: token receiver should receive the tokens
        assertEq(IERC20(_token0).balanceOf(_tokenReceiver), REMOVAL_AMOUNT, "Token receiver should receive the tokens");

        /// THEN: fees accumulated should remain unchanged
        assertEq(
            pair.token0FeesAccumulated(),
            _initialToken0FeesAccumulated,
            "Fees accumulated should remain unchanged"
        );
    }

    function test_CanRemoveToken1() public {
        address _token1 = pair.token1();
        uint256 _initialTokenBalance = IERC20(_token1).balanceOf(address(pair));
        uint256 _initialToken1FeesAccumulated = pair.token1FeesAccumulated();
        address _tokenReceiver = pair.tokenReceiverAddress();

        assertTrue({ err: "/// GIVEN: token1 balance is not 0", data: _initialTokenBalance > REMOVAL_AMOUNT });

        /// WHEN: tokenRemover calls removeTokens with token1
        hoax(tokenRemoverAddress);
        pair.removeTokens(_token1, REMOVAL_AMOUNT);

        /// THEN: token balance should decrease by removal amount
        assertEq(
            IERC20(_token1).balanceOf(address(pair)),
            _initialTokenBalance - REMOVAL_AMOUNT,
            "Token balance should decrease by removal amount"
        );

        /// THEN: token receiver should receive the tokens
        assertEq(IERC20(_token1).balanceOf(_tokenReceiver), REMOVAL_AMOUNT, "Token receiver should receive the tokens");

        /// THEN: fees accumulated should remain unchanged
        assertEq(
            pair.token1FeesAccumulated(),
            _initialToken1FeesAccumulated,
            "Fees accumulated should remain unchanged"
        );
    }

    function test_CannotRemoveToken0IfNotTokenRemover() public {
        address _token0 = pair.token0();
        uint256 _initialTokenBalance = IERC20(_token0).balanceOf(address(pair));

        /// WHEN: unprivileged user calls removeTokens with token0
        vm.expectRevert(abi.encodeWithSelector(AgoraAccessControl.AddressIsNotRole.selector, TOKEN_REMOVER_ROLE));
        pair.removeTokens(_token0, REMOVAL_AMOUNT);

        /// THEN: token balance should remain unchanged
        assertEq(
            IERC20(_token0).balanceOf(address(pair)),
            _initialTokenBalance,
            "Token balance should remain unchanged"
        );
    }

    function test_CannotRemoveToken1IfNotTokenRemover() public {
        address _token1 = pair.token1();
        uint256 _initialTokenBalance = IERC20(_token1).balanceOf(address(pair));

        /// WHEN: unprivileged user calls removeTokens with token1
        vm.expectRevert(abi.encodeWithSelector(AgoraAccessControl.AddressIsNotRole.selector, TOKEN_REMOVER_ROLE));
        pair.removeTokens(_token1, REMOVAL_AMOUNT);

        /// THEN: token balance should remain unchanged
        assertEq(
            IERC20(_token1).balanceOf(address(pair)),
            _initialTokenBalance,
            "Token balance should remain unchanged"
        );
    }

    function test_CannotRemoveMoreThanAvailableToken0() public {
        address _token0 = pair.token0();
        uint256 _availableBalance = IERC20(_token0).balanceOf(address(pair)) - pair.token0FeesAccumulated();

        /// WHEN: tokenRemover tries to remove more than available balance
        hoax(tokenRemoverAddress);
        vm.expectRevert(AgoraStableSwapPairCore.InsufficientTokens.selector);
        pair.removeTokens(_token0, _availableBalance + 1);
    }

    function test_CannotRemoveMoreThanAvailableToken1() public {
        address _token1 = pair.token1();
        uint256 _availableBalance = IERC20(_token1).balanceOf(address(pair)) - pair.token1FeesAccumulated();

        /// WHEN: tokenRemover tries to remove more than available balance
        hoax(tokenRemoverAddress);
        vm.expectRevert(AgoraStableSwapPairCore.InsufficientTokens.selector);
        pair.removeTokens(_token1, _availableBalance + 1);
    }

    function test_CanRemoveNonReserveToken() public {
        uint256 _initialBalance = IERC20(nonReserveToken).balanceOf(address(pair));
        address _tokenReceiver = pair.tokenReceiverAddress();

        /// WHEN: tokenRemover removes non-reserve token
        hoax(tokenRemoverAddress);
        pair.removeTokens(nonReserveToken, REMOVAL_AMOUNT);

        /// THEN: non-reserve token should be removed
        assertEq(
            IERC20(nonReserveToken).balanceOf(address(pair)),
            _initialBalance - REMOVAL_AMOUNT,
            "Non-reserve token balance should decrease"
        );

        /// THEN: token receiver should receive the tokens
        assertEq(
            IERC20(nonReserveToken).balanceOf(_tokenReceiver),
            REMOVAL_AMOUNT,
            "Token receiver should receive the non-reserve tokens"
        );

        /// THEN: reserve tokens and fees should remain unchanged
        assertEq(pair.token0FeesAccumulated(), pair.token0FeesAccumulated(), "Token0 fees should remain unchanged");
        assertEq(pair.token1FeesAccumulated(), pair.token1FeesAccumulated(), "Token1 fees should remain unchanged");
    }
}
