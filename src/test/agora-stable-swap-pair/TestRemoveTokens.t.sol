// // SPDX-License-Identifier: ISC
// pragma solidity ^0.8.28;

// import "src/test/BaseTest.sol";

// /* solhint-disable func-name-mixedcase */
// contract TestRemoveTokens is BaseTest {
//     /// FEATURE: Remove tokens from the pair

//     function setUp() public {
//         /// BACKGROUND:
//         _defaultSetup();

//         assertTrue({
//             err: "/// GIVEN: tokenRemover has privileges over the pair",
//             data: pair.hasRole(TOKEN_REMOVER_ROLE, tokenRemoverAddress)
//         });
//     }

//     function test_CanRemoveToken0() public {
//         address _token0 = pair.token0();
//         /// GIVEN: token0 balance is not 0
//         uint256 _initialTokenBalance = IERC20(_token0).balanceOf(address(pair));
//         assertTrue({ err: "/// GIVEN: token0 balance is not 0", data: _initialTokenBalance > 0 });

//         /// WHEN tokenRemover calls removeTokens with token0
//         hoax(tokenRemoverAddress);
//         pair.removeTokens(_token0, _initialTokenBalance);

//         uint256 _finalTokenBalance = IERC20(_token0).balanceOf(address(pair));
//         assertTrue({ err: "/// THEN: token0 balance should be 0", data: _finalTokenBalance == 0 });
//     }

//     function test_CannotRemoveToken0IfNotTokenRemover() public {
//         /// GIVEN: token0 balance is not 0
//         address _token0 = pair.token0();
//         uint256 _initialTokenBalance = IERC20(_token0).balanceOf(address(pair));
//         assertTrue({ err: "/// GIVEN: token0 balance is not 0", data: _initialTokenBalance > 0 });

//         /// WHEN unpriviledged user calls removeTokens with token0
//         /// THEN: call reverts and token0 balance should not have changed
//         vm.expectRevert(abi.encodeWithSelector(AgoraAccessControl.AddressIsNotRole.selector, TOKEN_REMOVER_ROLE));
//         pair.removeTokens(_token0, _initialTokenBalance);

//         uint256 _finalTokenBalance = IERC20(_token0).balanceOf(address(pair));
//         assertTrue({
//             err: "/// THEN: token0 balance should not have changed",
//             data: _finalTokenBalance == _initialTokenBalance
//         });
//     }

//     function test_CanRemoveToken1() public {
//         /// GIVEN: token1 balance is not 0
//         address _token1 = pair.token1();
//         uint256 _initialTokenBalance = IERC20(_token1).balanceOf(address(pair));
//         assertTrue({ err: "/// GIVEN: token1 balance is not 0", data: _initialTokenBalance > 0 });

//         /// WHEN tokenRemover calls removeTokens with token1
//         hoax(tokenRemoverAddress);
//         pair.removeTokens(_token1, _initialTokenBalance);

//         uint256 _finalTokenBalance = IERC20(_token1).balanceOf(address(pair));
//         assertTrue({ err: "/// THEN: token1 balance should be 0", data: _finalTokenBalance == 0 });
//     }

//     function test_CannotRemoveToken1IfNotTokenRemover() public {
//         /// GIVEN: token1 balance is not 0
//         address _token1 = pair.token1();
//         uint256 _initialTokenBalance = IERC20(_token1).balanceOf(address(pair));
//         assertTrue({ err: "/// GIVEN: token1 balance is not 0", data: _initialTokenBalance > 0 });

//         /// WHEN unpriviledged user calls removeTokens with token1
//         /// THEN: call reverts and token1 balance should not have changed
//         vm.expectRevert(abi.encodeWithSelector(AgoraAccessControl.AddressIsNotRole.selector, TOKEN_REMOVER_ROLE));
//         pair.removeTokens(_token1, _initialTokenBalance);

//         uint256 _finalTokenBalance = IERC20(_token1).balanceOf(address(pair));
//         assertTrue({
//             err: "/// THEN: token1 balance should not have changed",
//             data: _finalTokenBalance == _initialTokenBalance
//         });
//     }
// }
