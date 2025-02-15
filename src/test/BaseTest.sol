// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { StdAssertions, StdChains, StdCheats, StdInvariant, StdStorage, StdStyle, StdUtils, Test, TestBase, Vm, console2 as console, stdError, stdJson, stdMath, stdStorage } from "forge-std/Test.sol";

import "../Constants.sol" as Constants;
import "./Helpers.sol";

import { IERC20Errors as IErc20Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { ITransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import { BaseScript } from "script/BaseScript.sol";
import { DeployAgoraStableSwapPairReturn, deployAgoraStableSwapPair } from "script/deploy/deployAgoraStableSwapContracts.s.sol";

import { AgoraAccessControl } from "agora-contracts/access-control/AgoraAccessControl.sol";

import { AgoraProxyAdmin } from "agora-contracts/proxy/AgoraProxyAdmin.sol";
import { AgoraStableSwapPair, InitializeParams as AgoraStableSwapPairParams } from "contracts/AgoraStableSwapPair.sol";
import { AgoraStableSwapPairCore } from "contracts/AgoraStableSwapPairCore.sol";

contract BaseTest is Test, VmHelper, Constants.Helper {
    using AddressHelper for address;
    using BytesHelper for bytes32;
    using stdStorage for StdStorage;
    using SafeCast for *;
    using StringsHelper for *;
    using ArrayHelper for *;

    // User convenience variables
    address public proxyAdminOwnerAddress;

    address public adminAddress;
    string public constant ACCESS_CONTROL_ADMIN_ROLE = "ACCESS_CONTROL_ADMIN_ROLE";

    address public whitelisterAddress;
    string public constant WHITELISTER_ROLE = "WHITELISTER_ROLE";

    address public feeSetterAddress;
    string public constant FEE_SETTER_ROLE = "FEE_SETTER_ROLE";

    address public tokenRemoverAddress;
    string public constant TOKEN_REMOVER_ROLE = "TOKEN_REMOVER_ROLE";

    address public pauserAddress;
    string public constant PAUSER_ROLE = "PAUSER_ROLE";

    address public priceSetterAddress;
    string public constant PRICE_SETTER_ROLE = "PRICE_SETTER_ROLE";

    string public constant APPROVED_SWAPPER = "APPROVED_SWAPPER";

    address public tokenReceiverAddress;
    address public feeReceiverAddress;

    // ProxyAdminConvenience variables
    address public proxyAdminAddress;
    AgoraProxyAdmin public proxyAdmin;

    // Pair convenience variables
    address public pairImplementationAddress;
    AgoraStableSwapPair public pairImplementation;

    address public pairAddress;
    AgoraStableSwapPair public pair;

    function _defaultSetup() internal returns (AgoraStableSwapPairParams memory _agoraStableSwapPairParams) {
        // set env to block 21359209
        vm.createSelectFork("eth_mainnet", 21_359_209);

        // Set roles
        _setGlobalRoleVariables({
            _proxyAdminOwnerAddress: labelAndDeal("proxyAdminOwnerAddress"),
            _adminAddress: labelAndDeal("adminAddress"),
            _whitelisterAddress: labelAndDeal("whitelisterAddress"),
            _feeSetterAddress: labelAndDeal("feeSetterAddress"),
            _tokenRemoverAddress: labelAndDeal("tokenRemoverAddress"),
            _pauserAddress: labelAndDeal("pauserAddress"),
            _priceSetterAddress: labelAndDeal("priceSetterAddress"),
            _tokenReceiverAddress: labelAndDeal("tokenReceiverAddress"),
            _feeReceiverAddress: labelAndDeal("feeReceiverAddress")
        });

        // Deploy Contracts
        AgoraProxyAdmin _proxyAdmin = new AgoraProxyAdmin(proxyAdminOwnerAddress);

        _agoraStableSwapPairParams = AgoraStableSwapPairParams({
            token0: Constants.Mainnet.AUSD_ERC20,
            token0Decimals: 6,
            token1: Constants.Mainnet.WETH_ERC20,
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

        DeployAgoraStableSwapPairReturn memory _pairDeployment = deployAgoraStableSwapPair(
            address(_proxyAdmin),
            _agoraStableSwapPairParams
        );

        _setGlobalContractVariables({
            _proxyAdmin: _proxyAdmin,
            _pairImplementation: AgoraStableSwapPair(_pairDeployment.agoraStableSwapPairImplementation),
            _pair: AgoraStableSwapPair(_pairDeployment.agoraStableSwapPair)
        });

        // Assign Roles to Pair
        _assignRolesToPair({
            _pair: pair,
            _whitelisterAddress: whitelisterAddress,
            _feeSetterAddress: feeSetterAddress,
            _tokenRemoverAddress: tokenRemoverAddress,
            _pauserAddress: pauserAddress,
            _priceSetterAddress: priceSetterAddress
        });

        _seedErc20({ _tokenAddress: pair.token0(), _to: pairAddress, _amount: 2e6 * 1e6 });
        _seedErc20({ _tokenAddress: pair.token1(), _to: pairAddress, _amount: 1e18 });
        pair.sync();

        // Add the default caller to approved swapper list
        _setApprovedSwapperAsWhitelister(pair, address(this));

        return _agoraStableSwapPairParams;
    }

    function _setApprovedSwapperAsWhitelister(AgoraStableSwapPair _pair, address _newSwapper) internal {
        hoax(_pair.getRoleMembers(WHITELISTER_ROLE)[0]);
        _pair.setApprovedSwappers(new address[](0).concat(_newSwapper), true);
    }

    function _setFeesAsFeeSetter(
        AgoraStableSwapPair _pair,
        uint256 _token0PurchaseFee,
        uint256 _token1PurchaseFee
    ) internal {
        hoax(_pair.getRoleMembers(FEE_SETTER_ROLE)[0]);
        _pair.setTokenPurchaseFees(_token0PurchaseFee, _token1PurchaseFee);
    }

    function _setOraclePriceBoundsAsAdmin(
        AgoraStableSwapPair _pair,
        uint256 _minBasePrice,
        uint256 _maxBasePrice,
        int256 _minAnnualizedInterestRate,
        int256 _maxAnnualizedInterestRate
    ) internal {
        hoax(_pair.getRoleMembers(ACCESS_CONTROL_ADMIN_ROLE)[0]);
        _pair.setOraclePriceBounds(
            _minBasePrice,
            _maxBasePrice,
            _minAnnualizedInterestRate,
            _maxAnnualizedInterestRate
        );
    }

    function _configureOraclePriceAsPriceSetter(
        AgoraStableSwapPair _pair,
        uint256 _basePrice,
        int256 _annualizedInterestRate
    ) internal {
        hoax(_pair.getRoleMembers(PRICE_SETTER_ROLE)[0]);
        _pair.configureOraclePrice(_basePrice, _annualizedInterestRate);
    }

    function _setFeeBoundsAsAdmin(
        AgoraStableSwapPair _pair,
        uint256 _minToken0PurchaseFee,
        uint256 _maxToken0PurchaseFee,
        uint256 _minToken1PurchaseFee,
        uint256 _maxToken1PurchaseFee
    ) internal {
        hoax(_pair.getRoleMembers(ACCESS_CONTROL_ADMIN_ROLE)[0]);
        _pair.setFeeBounds(_minToken0PurchaseFee, _maxToken0PurchaseFee, _minToken1PurchaseFee, _maxToken1PurchaseFee);
    }

    function _setGlobalRoleVariables(
        address _proxyAdminOwnerAddress,
        address _adminAddress,
        address _whitelisterAddress,
        address _feeSetterAddress,
        address _tokenRemoverAddress,
        address _pauserAddress,
        address _priceSetterAddress,
        address _tokenReceiverAddress,
        address _feeReceiverAddress
    ) internal {
        proxyAdminOwnerAddress = _proxyAdminOwnerAddress;
        adminAddress = _adminAddress;
        whitelisterAddress = _whitelisterAddress;
        feeSetterAddress = _feeSetterAddress;
        tokenRemoverAddress = _tokenRemoverAddress;
        pauserAddress = _pauserAddress;
        priceSetterAddress = _priceSetterAddress;
        tokenReceiverAddress = _tokenReceiverAddress;
        feeReceiverAddress = _feeReceiverAddress;
    }

    function _setGlobalContractVariables(
        AgoraProxyAdmin _proxyAdmin,
        AgoraStableSwapPair _pairImplementation,
        AgoraStableSwapPair _pair
    ) internal {
        proxyAdmin = _proxyAdmin;
        proxyAdminAddress = address(_proxyAdmin);

        pairImplementation = _pairImplementation;
        pairImplementationAddress = address(_pairImplementation);

        pair = _pair;
        pairAddress = address(_pair);
    }

    function _assignRolesToPair(
        AgoraStableSwapPair _pair,
        address _whitelisterAddress,
        address _feeSetterAddress,
        address _tokenRemoverAddress,
        address _pauserAddress,
        address _priceSetterAddress
    ) internal {
        /// BACKGROUND: adminAddress sets minterAddress, pauserAddress, burnerAddress, freezerAddress on the deployed contract
        address[] memory _adminAddresses = _pair.getRoleMembers(ACCESS_CONTROL_ADMIN_ROLE);
        startHoax(_adminAddresses[0]);
        _pair.assignRole(WHITELISTER_ROLE, _whitelisterAddress, true);
        _pair.assignRole(FEE_SETTER_ROLE, _feeSetterAddress, true);
        _pair.assignRole(TOKEN_REMOVER_ROLE, _tokenRemoverAddress, true);
        _pair.assignRole(PAUSER_ROLE, _pauserAddress, true);
        _pair.assignRole(PRICE_SETTER_ROLE, _priceSetterAddress, true);
        vm.stopPrank();
    }

    function _seedErc20(address _tokenAddress, address _to, uint256 _amount) internal {
        stdstore.enable_packed_slots().target(_tokenAddress).sig("balanceOf(address)").with_key(_to).checked_write(
            _amount
        );
    }

    function _calculatePriceWithFfi(
        uint256 _lastUpdated,
        uint256 _currentTimestamp,
        int256 _perSecondInterestRate,
        uint256 _price
    ) internal returns (uint256 _result) {
        string[] memory _inputs = new string[](0)
            .concat("node")
            .concat("src/test/helpers/calculatePrice.js")
            .concat(_lastUpdated.toString())
            .concat(_currentTimestamp.toString())
            .concat(_perSecondInterestRate.toString())
            .concat(_price.toString());
        bytes memory response = vm.ffi(_inputs);
        _result = abi.decode(response, (uint256));
    }

    //==============================================================================
    // Address Snapshot Functions
    //==============================================================================

    struct AddressAccountingSnapshot {
        address selfAddress;
        uint256 etherBalance;
        uint256 token0Balance;
        uint256 token1Balance;
        bool isFrozen;
    }

    struct DeltaAddressAccountingSnapshot {
        AddressAccountingSnapshot start;
        AddressAccountingSnapshot end;
        AddressAccountingSnapshot delta;
    }

    function addressAccountingSnapshot(
        address _address
    ) internal view returns (AddressAccountingSnapshot memory _initial) {
        _initial.selfAddress = _address;
        _initial.etherBalance = _address.balance;
        _initial.token0Balance = IERC20(pair.token0()).balanceOf(_address);
        _initial.token1Balance = IERC20(pair.token1()).balanceOf(_address);
    }

    function calculateDeltaAddressAccounting(
        AddressAccountingSnapshot memory _initial,
        AddressAccountingSnapshot memory _final
    ) internal pure returns (AddressAccountingSnapshot memory _delta) {
        _delta.selfAddress = _initial.selfAddress == _final.selfAddress ? address(0) : _final.selfAddress;
        _delta.etherBalance = stdMath.delta(_final.etherBalance, _initial.etherBalance);
        _delta.token0Balance = stdMath.delta(_final.token0Balance, _initial.token0Balance);
        _delta.token1Balance = stdMath.delta(_final.token1Balance, _initial.token1Balance);
        _delta.isFrozen = _final.isFrozen == _initial.isFrozen ? false : true;
    }

    function deltaAddressAccountingSnapshot(
        AddressAccountingSnapshot memory _initial
    ) internal view returns (DeltaAddressAccountingSnapshot memory _end) {
        _end.start = _initial;
        _end.end = addressAccountingSnapshot(_initial.selfAddress);
        _end.delta = calculateDeltaAddressAccounting(_end.start, _end.end);
    }

    function valueDeltaAddressAccountingSnapshot(
        DeltaAddressAccountingSnapshot memory _delta
    ) internal view returns (uint256 _valueDelta) {
        _valueDelta = _delta.delta.token0Balance * pair.getPrice() + _delta.delta.token1Balance;
    }

    //==============================================================================
    // Pair Snapshot Functions
    //==============================================================================

    struct PairStateSnapshot {
        // General
        AgoraStableSwapPair self;
        address selfAddress;
        // SwapStorage
        bool isPaused;
        address token0;
        address token1;
        uint112 reserve0;
        uint112 reserve1;
        uint64 token0PurchaseFee; // 18 decimals precision, max value 1
        uint64 token1PurchaseFee; // 18 decimals precision, max value 1
        uint40 priceLastUpdated;
        int72 perSecondInterestRate; // 18 decimals of precision, given as whole number i.e. 1e16 = 1%
        uint256 basePrice;
        uint128 token0FeesAccumulated;
        uint128 token1FeesAccumulated;
        // ConfigStorage
        uint256 minToken0PurchaseFee; // 18 decimals precision, max value 1
        uint256 maxToken0PurchaseFee; // 18 decimals precision, max value 1
        uint256 minToken1PurchaseFee; // 18 decimals precision, max value 1
        uint256 maxToken1PurchaseFee; // 18 decimals precision, max value 1
        address tokenReceiverAddress;
        address feeReceiverAddress;
        uint256 minBasePrice; // 18 decimals precision, max value determined by difference between decimals of token0 and token1
        uint256 maxBasePrice; // 18 decimals precision, max value determined by difference between decimals of token0 and token1
        int256 minAnnualizedInterestRate; // 18 decimals precision, given as number i.e. 1e16 = 1%
        int256 maxAnnualizedInterestRate; // 18 decimals precision, given as number i.e. 1e16 = 1%
        uint8 token0Decimals;
        uint8 token1Decimals;
    }

    struct DeltaPairStateSnapshot {
        PairStateSnapshot start;
        PairStateSnapshot end;
        PairStateSnapshot delta;
    }

    function pairStateSnapshot() internal view returns (PairStateSnapshot memory _initial) {
        return pairStateSnapshot(pairAddress);
    }

    function pairStateSnapshot(address _address) internal view returns (PairStateSnapshot memory _initial) {
        if (_address == address(0)) revert("PairStateSnapshot: address is zero");
        AgoraStableSwapPair _pair = AgoraStableSwapPair(_address);

        // general
        _initial.self = _pair;
        _initial.selfAddress = _address;

        // swapStorage
        _initial.isPaused = _pair.isPaused();
        _initial.token0 = _pair.token0();
        _initial.token1 = _pair.token1();
        _initial.reserve0 = _pair.reserve0().toUint112();
        _initial.reserve1 = _pair.reserve1().toUint112();
        _initial.token0PurchaseFee = _pair.token0PurchaseFee().toUint64();
        _initial.token1PurchaseFee = _pair.token1PurchaseFee().toUint64();
        _initial.priceLastUpdated = _pair.priceLastUpdated().toUint40();
        _initial.perSecondInterestRate = _pair.perSecondInterestRate().toInt72();
        _initial.basePrice = _pair.basePrice();
        _initial.token0FeesAccumulated = _pair.token0FeesAccumulated().toUint128();
        _initial.token1FeesAccumulated = _pair.token1FeesAccumulated().toUint128();

        // configStorage
        _initial.minToken0PurchaseFee = _pair.minToken0PurchaseFee();
        _initial.maxToken0PurchaseFee = _pair.maxToken0PurchaseFee();
        _initial.minToken1PurchaseFee = _pair.minToken1PurchaseFee();
        _initial.maxToken1PurchaseFee = _pair.maxToken1PurchaseFee();
        _initial.tokenReceiverAddress = _pair.tokenReceiverAddress();
        _initial.feeReceiverAddress = _pair.feeReceiverAddress();
        _initial.minBasePrice = _pair.minBasePrice();
        _initial.maxBasePrice = _pair.maxBasePrice();
        _initial.minAnnualizedInterestRate = _pair.minAnnualizedInterestRate();
        _initial.maxAnnualizedInterestRate = _pair.maxAnnualizedInterestRate();
        _initial.token0Decimals = _pair.token0Decimals();
        _initial.token1Decimals = _pair.token1Decimals();
    }

    function calculateDeltaPairStateSnapshot(
        PairStateSnapshot memory _initial,
        PairStateSnapshot memory _final
    ) internal pure returns (PairStateSnapshot memory _delta) {
        // general
        _delta.self = _initial.self;
        _delta.selfAddress = _initial.selfAddress == _final.selfAddress ? address(0).toPayable() : _final.selfAddress;

        // swapStorage
        _delta.isPaused = _final.isPaused == _initial.isPaused ? false : true;
        _delta.token0 = _initial.token0 == _final.token0 ? address(0) : _final.token0;
        _delta.token1 = _initial.token1 == _final.token1 ? address(0) : _final.token1;
        _delta.reserve0 = stdMath.delta(_final.reserve0, _initial.reserve0).toUint112();
        _delta.reserve1 = stdMath.delta(_final.reserve1, _initial.reserve1).toUint112();
        _delta.token0PurchaseFee = stdMath.delta(_final.token0PurchaseFee, _initial.token0PurchaseFee).toUint64();
        _delta.token1PurchaseFee = stdMath.delta(_final.token1PurchaseFee, _initial.token1PurchaseFee).toUint64();
        _delta.priceLastUpdated = stdMath.delta(_final.priceLastUpdated, _initial.priceLastUpdated).toUint40();
        _delta.perSecondInterestRate = stdMath
            .delta(_final.perSecondInterestRate, _initial.perSecondInterestRate)
            .toInt256()
            .toInt72();
        _delta.basePrice = stdMath.delta(_final.basePrice, _initial.basePrice);
        _delta.token0FeesAccumulated = stdMath
            .delta(_final.token0FeesAccumulated, _initial.token0FeesAccumulated)
            .toUint128();
        _delta.token1FeesAccumulated = stdMath
            .delta(_final.token1FeesAccumulated, _initial.token1FeesAccumulated)
            .toUint128();

        // configStorage
        _delta.minToken0PurchaseFee = stdMath.delta(_final.minToken0PurchaseFee, _initial.minToken0PurchaseFee);
        _delta.maxToken0PurchaseFee = stdMath.delta(_final.maxToken0PurchaseFee, _initial.maxToken0PurchaseFee);
        _delta.minToken1PurchaseFee = stdMath.delta(_final.minToken1PurchaseFee, _initial.minToken1PurchaseFee);
        _delta.maxToken1PurchaseFee = stdMath.delta(_final.maxToken1PurchaseFee, _initial.maxToken1PurchaseFee);
        _delta.tokenReceiverAddress = _initial.tokenReceiverAddress == _final.tokenReceiverAddress
            ? address(0)
            : _final.tokenReceiverAddress;
        _delta.feeReceiverAddress = _initial.feeReceiverAddress == _final.feeReceiverAddress
            ? address(0)
            : _final.feeReceiverAddress;
        _delta.minBasePrice = stdMath.delta(_final.minBasePrice, _initial.minBasePrice);
        _delta.maxBasePrice = stdMath.delta(_final.maxBasePrice, _initial.maxBasePrice);
        _delta.minAnnualizedInterestRate = stdMath
            .delta(_final.minAnnualizedInterestRate, _initial.minAnnualizedInterestRate)
            .toInt256();
        _delta.maxAnnualizedInterestRate = stdMath
            .delta(_final.maxAnnualizedInterestRate, _initial.maxAnnualizedInterestRate)
            .toInt256();
        _delta.token0Decimals = _initial.token0Decimals == _final.token0Decimals ? 0 : _final.token0Decimals;
        _delta.token1Decimals = _initial.token1Decimals == _final.token1Decimals ? 0 : _final.token1Decimals;
    }

    function deltaPairStateAccountingSnapshot(
        PairStateSnapshot memory _initial
    ) internal view returns (DeltaPairStateSnapshot memory _end) {
        _end.start = _initial;
        _end.end = pairStateSnapshot(_initial.selfAddress);
        _end.delta = calculateDeltaPairStateSnapshot(_end.start, _end.end);
    }
}
