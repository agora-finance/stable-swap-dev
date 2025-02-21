// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { AgoraTransparentUpgradeableProxy, ConstructorParams as AgoraTransparentUpgradeableProxyParams } from "agora-contracts/proxy/AgoraTransparentUpgradeableProxy.sol";
import { SymTest } from "halmos-cheatcodes/SymTest.sol";
import "src/test/BaseTest.sol";

contract SwapAmountsTest is SymTest, BaseTest {
    address payable public alice = payable(address(0x20ff));

    address token0Address;
    address token1Address;

    IERC20 token0;
    IERC20 token1;

    function _setUp(TestToken _token0, TestToken _token1) public {
        // Set roles
        proxyAdminOwnerAddress = address(0x10);
        adminAddress = address(0x20);
        whitelisterAddress = address(0x30);
        feeSetterAddress = address(0x40);
        tokenRemoverAddress = address(0x50);
        pauserAddress = address(0x60);
        priceSetterAddress = address(0x70);
        tokenReceiverAddress = address(0x80);
        feeReceiverAddress = address(0x90);

        // Deploy Contracts
        AgoraProxyAdmin _proxyAdmin = new AgoraProxyAdmin(proxyAdminOwnerAddress);

        AgoraStableSwapPairParams memory _agoraStableSwapPairParams = AgoraStableSwapPairParams({
            token0: address(_token0),
            token0Decimals: 6,
            token1: address(_token1),
            token1Decimals: 18,
            minToken0PurchaseFee: 0,
            maxToken0PurchaseFee: 2e16,
            minToken1PurchaseFee: 0,
            maxToken1PurchaseFee: 5e16,
            token0PurchaseFee: 0,
            token1PurchaseFee: 0,
            initialAdminAddress: adminAddress,
            initialWhitelister: whitelisterAddress,
            initialFeeSetter: feeSetterAddress,
            initialTokenRemover: tokenRemoverAddress,
            initialPauser: pauserAddress,
            initialPriceSetter: priceSetterAddress,
            initialTokenReceiver: tokenReceiverAddress,
            initialFeeReceiver: feeReceiverAddress,
            minBasePrice: 1e6,
            maxBasePrice: 3e18,
            minAnnualizedInterestRate: 0,
            maxAnnualizedInterestRate: 5e16,
            basePrice: 2e18,
            annualizedInterestRate: 5e16
        });

        AgoraStableSwapPair _pairImplementation = new AgoraStableSwapPair();
        AgoraTransparentUpgradeableProxy _pairProxy = new AgoraTransparentUpgradeableProxy(
            AgoraTransparentUpgradeableProxyParams({
                logic: address(_pairImplementation),
                proxyAdminAddress: address(_proxyAdmin),
                data: abi.encodeWithSelector(AgoraStableSwapPair.initialize.selector, _agoraStableSwapPairParams)
            })
        );

        proxyAdmin = _proxyAdmin;
        proxyAdminAddress = address(_proxyAdmin);

        pairImplementation = _pairImplementation;
        pairImplementationAddress = address(_pairImplementation);

        pair = AgoraStableSwapPair(address(_pairProxy));
        pairAddress = address(_pairProxy);

        //
        // PAIR SETUP
        //
        token0Address = pair.token0();
        token1Address = pair.token1();

        token0 = IERC20(token0Address);
        token1 = IERC20(token1Address);

        _setApprovedSwapperAsWhitelister({ _pair: pair, _newSwapper: alice });

        // Just give a lot so view fns don't revert with insufficient liquidity errors
        TestToken(address(token0)).mint(alice, 1e18 * 1e10);
        TestToken(address(token1)).mint(alice, 1e18 * 1e10);
        TestToken(address(token0)).mint(pairAddress, 1e18 * 1e10);
        TestToken(address(token1)).mint(pairAddress, 1e18 * 1e10);
        pair.sync();

        hoax(alice);
        token0.approve(address(pair), type(uint256).max);
        token1.approve(address(pair), type(uint256).max);
    }

    //
    // CHECK: Amount 0 prices are consistent across view functions.
    //
    function check_price_1(
        uint8 token0Decimals,
        uint8 token1Decimals,
        uint256 oraclePrice,
        uint256 fee0,
        uint256 fee1
    ) public {
        // function check_price_1() public {
        // uint8 token0Decimals = 6; uint8 token1Decimals=18; uint oraclePrice=1.2e18; uint fee0=1e16; uint fee1=1e16;
        vm.assume(token0Decimals >= 6);
        vm.assume(token0Decimals <= 18);
        vm.assume(token1Decimals >= 6);
        vm.assume(token1Decimals <= 18);

        // Deploy test tokens
        TestToken _token0 = new TestToken("Test AUSD", "TAUSD", token0Decimals);
        TestToken _token1 = new TestToken("Test WETH", "TWETH", token1Decimals);
        _setUp(_token0, _token1);

        // Make price centered around 1 (i.e. 1e18)
        vm.assume(oraclePrice > 5e17);
        vm.assume(oraclePrice < 2e18);
        vm.assume(fee0 < 1e18);
        vm.assume(fee1 < 1e18);

        // set price
        vm.prank(priceSetterAddress);
        pair.configureOraclePrice(oraclePrice, 5e16 /* 5% */);

        vm.prank(feeSetterAddress);
        pair.setTokenPurchaseFees(fee0, fee1);

        uint256 _amount1Out = 1e18;
        uint256 _price = pair.getPrice();

        (uint256 _expectedAmount0In, uint256 _expectedToken1PurchaseFeeAmount) = pair.getAmount0In(
            _amount1Out,
            _price,
            fee1
        );

        address[] memory _pathIn0 = new address[](2);
        _pathIn0[0] = address(token0);
        _pathIn0[1] = address(token1);
        uint256[] memory _amountsIn0 = pair.getAmountsIn(_amount1Out, _pathIn0);
        assert(_amountsIn0[0] == _expectedAmount0In);
        assertEq(_amountsIn0[1], _amount1Out);
    }

    //
    // CHECK: Amount 0 prices are consistent across view functions.
    // NOTE: This is duplicated because having multiple asserts makes halmos run exponentially higher
    //
    function check_price_2(
        uint8 token0Decimals,
        uint8 token1Decimals,
        uint256 oraclePrice,
        uint256 fee0,
        uint256 fee1
    ) public {
        vm.assume(token0Decimals >= 6);
        vm.assume(token0Decimals <= 18);
        vm.assume(token1Decimals >= 6);
        vm.assume(token1Decimals <= 18);

        // Deploy test tokens
        TestToken _token0 = new TestToken("Test AUSD", "TAUSD", token0Decimals);
        TestToken _token1 = new TestToken("Test WETH", "TWETH", token1Decimals);
        _setUp(_token0, _token1);

        // Make price centered around 1 (i.e. 1e18)
        vm.assume(oraclePrice > 5e17);
        vm.assume(oraclePrice < 2e18);
        vm.assume(fee0 < 1e18);
        vm.assume(fee1 < 1e18);

        // set price
        vm.prank(priceSetterAddress);
        pair.configureOraclePrice(oraclePrice, 5e16 /* 5% */);

        vm.prank(feeSetterAddress);
        pair.setTokenPurchaseFees(fee0, fee1);

        uint256 _amount0Out = 1e18;
        uint256 _price = pair.getPrice();

        (uint256 _expectedAmount1In, uint256 _expectedToken0PurchaseFeeAmount) = pair.getAmount1In(
            _amount0Out,
            _price,
            fee0
        );

        address[] memory _pathIn1 = new address[](2);
        _pathIn1[0] = address(token1);
        _pathIn1[1] = address(token0);
        uint256[] memory _amountsIn1 = pair.getAmountsIn(_amount0Out, _pathIn1);
        assert(_amountsIn1[0] == _expectedAmount1In);
        assertEq(_amountsIn1[1], _amount0Out);
    }
}

contract TestToken is ERC20, Ownable {
    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint8 decimalsValue) ERC20(name, symbol) Ownable(msg.sender) {
        _decimals = decimalsValue;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}
