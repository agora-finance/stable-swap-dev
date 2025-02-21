// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { AgoraTransparentUpgradeableProxy, ConstructorParams as AgoraTransparentUpgradeableProxyParams } from "agora-contracts/proxy/AgoraTransparentUpgradeableProxy.sol";
import { SymTest } from "halmos-cheatcodes/SymTest.sol";
import "src/test/BaseTest.sol";

contract PairSwapTest is SymTest, BaseTest {
    address payable public alice = payable(address(0x20ff));

    address token0Address;
    address token1Address;

    IERC20 token0;
    IERC20 token1;

    function setUp() public {
        // vm.createSelectFork("eth_mainnet", 21_359_209);
        //
        // ENV SETUP
        //
        // Deploy test tokens
        TestToken _token0 = new TestToken("Test AUSD", "TAUSD", 6); // 6 decimals like USDC
        TestToken _token1 = new TestToken("Test WETH", "TWETH", 18); // 18 decimals like WETH

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

        TestToken(address(token0)).mint(alice, 1e6 * 1e18); // A gazillion TAUSD
        TestToken(address(token1)).mint(alice, 1e18 * 1e6); // A million TWETH

        TestToken(address(token0)).mint(pairAddress, 1e6 * 1_000_000);
        TestToken(address(token1)).mint(pairAddress, 1e18 * 5000);
        pair.sync();

        hoax(alice);
        token0.approve(address(pair), type(uint256).max);
        token1.approve(address(pair), type(uint256).max);
    }

    //
    // CHECK: When outputting Y with an expected input of X,
    //        sender can't input anything less than X.
    //
    function check_swap_1(uint256 amount0In, uint256 amount1Out) public {
        uint256 FEE = 1e16; /* 1% */
        // set price
        vm.prank(priceSetterAddress);
        pair.configureOraclePrice(1.2e6, /* 1.2 AUSD */ 5e16 /* 5% */);

        vm.prank(feeSetterAddress);
        pair.setTokenPurchaseFees(FEE, /* 1% */ FEE /* 1% */);

        uint256 token0_start = token0.balanceOf(alice);

        //
        // Choose an arbitrary amount we're trying to get out of the pool
        //
        vm.assume(amount1Out > 0);
        vm.assume(amount1Out <= token0.balanceOf(address(pair)));

        uint256 _price = pair.getPrice();
        (uint256 _expectedAmount0In, ) = pair.getAmount0In(amount1Out, _price, FEE);

        //
        // Check against input amounts that are lower than expected
        //
        vm.assume(amount0In > 0);
        vm.assume(amount0In <= _expectedAmount0In);

        startHoax(alice);
        token0.transfer(address(pair), amount0In);
        pair.swap(0, amount1Out, alice, "");

        uint256 token0_end = token0.balanceOf(alice);

        uint256 _token0Spent = token0_start - token0_end;
        assert(_token0Spent == _expectedAmount0In);
    }

    //
    // CHECK: When outputting Y with an expected input of X,
    //        sender can't input anything less than X,
    //        even when inputting some arbitrary amount of Y.
    //
    function check_swap_2(uint256 amount0In, uint256 amount1In, uint256 amount1Out) public {
        uint256 FEE = 1e16; /* 1% */
        // set price
        vm.prank(priceSetterAddress);
        pair.configureOraclePrice(2e6, /* 2 AUSD */ 5e16 /* 5% */);

        vm.prank(feeSetterAddress);
        pair.setTokenPurchaseFees(FEE, /* 1% */ FEE /* 1% */);

        uint256 token0_start = token0.balanceOf(alice);

        //
        // Choose an arbitrary amount we're trying to get out of the pool
        //
        vm.assume(amount1Out > 0);
        vm.assume(amount1Out <= token0.balanceOf(address(pair)));

        uint256 _price = pair.getPrice();
        (uint256 _expectedAmount0In, ) = pair.getAmount0In(amount1Out, _price, FEE);

        //
        // Check against input amounts that are lower than expected
        //
        vm.assume(amount0In > 0);
        vm.assume(amount0In <= _expectedAmount0In);
        vm.assume(amount1In <= token1.balanceOf(address(pair)));

        startHoax(alice);
        token0.transfer(address(pair), amount0In);
        token1.transfer(address(pair), amount1In);
        pair.swap(0, amount1Out, alice, "");

        uint256 token0_end = token0.balanceOf(alice);

        uint256 _token0Spent = token0_start - token0_end;
        assert(_token0Spent == _expectedAmount0In);
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
