// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

// ====================================================================
//             _        ______     ___   _______          _
//            / \     .' ___  |  .'   `.|_   __ \        / \
//           / _ \   / .'   \_| /  .-.  \ | |__) |      / _ \
//          / ___ \  | |   ____ | |   | | |  __ /      / ___ \
//        _/ /   \ \_\ `.___]  |\  `-'  /_| |  \ \_  _/ /   \ \_
//       |____| |____|`._____.'  `.___.'|____| |___||____| |____|
// ====================================================================
// ===================== AgoraStableSwapRegistry ======================
// ====================================================================

import { AgoraStableSwapRegistryAccessControl } from "./AgoraStableSwapRegistryAccessControl.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import { IAgoraStableSwapPair } from "../interfaces/IAgoraStableSwapPair.sol";

/// @notice The ```Version``` struct is used to represent the version of the AgoraStableSwapRegistry
/// @param major The major version number
/// @param minor The minor version number
/// @param patch The patch version number
struct Version {
    uint256 major;
    uint256 minor;
    uint256 patch;
}

/// @title AgoraStableSwapRegistry
/// @notice The AgoraStableSwapRegistry contract is used to register and manage the addresses of the AgoraStableSwapPair contracts
/// @author Agora
contract AgoraStableSwapRegistry is Initializable, AgoraStableSwapRegistryAccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice a set of the current registered swap addresses
    /// @param registeredSwapAddresses A set of the current registered swap addresses
    struct AgoraStableSwapRegistryStorage {
        EnumerableSet.AddressSet registeredSwapAddresses;
    }

    //==============================================================================
    // Initialization Function
    //==============================================================================

    constructor() {
        _disableInitializers();
    }

    /// @notice The ```initialize``` function initializes the AgoraStableSwapRegistry contract
    /// @param _initialAdminAddress The address of the initial admin
    function initialize(address _initialAdminAddress) external initializer {
        _initializeAgoraStableSwapRegistryAccessControl({ _initialAdminAddress: _initialAdminAddress });
    }

    //==============================================================================
    // External Stateful Functions
    //==============================================================================

    // ! TODO: should this function emit an event?
    /// @notice the ```registerSwapAddress``` function registers a swap address
    /// @param _swapAddress the address of the swap to register
    /// @param _isRegistered the boolean value indicating whether the swap is registered
    function setSwapAddress(address _swapAddress, bool _isRegistered) external {
        _requireSenderIsRole({ _role: BOOKKEEPER_ROLE });
        if (_isRegistered) {
            _getPointerToAgoraStableSwapRegistryStorage().registeredSwapAddresses.add({ value: _swapAddress });
        } else {
            _getPointerToAgoraStableSwapRegistryStorage().registeredSwapAddresses.remove({ value: _swapAddress });
        }
    }

    /// @notice the ```executeOnRegisteredAddresses``` function executes a function call on all registered swap addresses
    /// @param _data the data to execute on the registered swap addresses
    function executeOnRegisteredAddresses(bytes calldata _data) external {
        _requireSenderIsRole({ _role: ADMIN_ROLE });
        address[] memory _registeredSwapAddresses = _getPointerToAgoraStableSwapRegistryStorage()
            .registeredSwapAddresses
            .values();
        for (uint256 i = 0; i < _registeredSwapAddresses.length; i++) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = _registeredSwapAddresses[i].call(_data);
            if (!success) revert CallToRegisteredSwapAddressFailed({ swapAddress: _registeredSwapAddresses[i] });
        }
    }

    /// @notice the ```tryExecuteOnRegisteredAddresses``` function tries to execute a function call on all registered swap addresses
    /// @param _data the data to execute on the registered swap addresses
    /// @return _successfulAddresses an array of the successful addresses
    /// @return _failedAddresses an array of the failed addresses
    function tryExecuteOnRegisteredAddresses(
        bytes calldata _data
    ) external returns (address[] memory _successfulAddresses, address[] memory _failedAddresses) {
        _requireIsRole({ _role: ADMIN_ROLE, _address: msg.sender });
        address[] memory _registeredSwapAddresses = _getPointerToAgoraStableSwapRegistryStorage()
            .registeredSwapAddresses
            .values();

        // instantiate the arrays to store the successful and failed addresses
        _successfulAddresses = new address[](_registeredSwapAddresses.length);
        _failedAddresses = new address[](_registeredSwapAddresses.length);

        for (uint256 i = 0; i < _registeredSwapAddresses.length; i++) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = _registeredSwapAddresses[i].call(_data);
            if (!success) _failedAddresses[i] = (_registeredSwapAddresses[i]);
            else _successfulAddresses[i] = (_registeredSwapAddresses[i]);
        }
    }

    /// @notice the ```tryWhitelistUserOnRegisteredAddresses``` function tries to whitelist a user on all registered swap addresses
    /// @param _address the address to whitelist
    /// @param _isApproved the boolean value indicating whether the address is approved
    /// @return _successfulAddresses an array of the successful addresses
    /// @return _failedAddresses an array of the failed addresses
    function tryWhitelistUserOnRegisteredAddresses(
        address _address,
        bool _isApproved
    ) external returns (address[] memory _successfulAddresses, address[] memory _failedAddresses) {
        _requireIsRole({ _role: WHITELISTER_ROLE, _address: msg.sender });
        address[] memory _registeredSwapAddresses = _getPointerToAgoraStableSwapRegistryStorage()
            .registeredSwapAddresses
            .values();

        // instantiate the arrays to store the successful and failed addresses
        _successfulAddresses = new address[](_registeredSwapAddresses.length);
        _failedAddresses = new address[](_registeredSwapAddresses.length);

        for (uint256 i = 0; i < _registeredSwapAddresses.length; i++) {
            try IAgoraStableSwapPair(_registeredSwapAddresses[i]).setApprovedSwapper(_address, _isApproved) {
                _successfulAddresses[i] = (_registeredSwapAddresses[i]);
            } catch {
                _failedAddresses[i] = (_registeredSwapAddresses[i]);
            }
        }
    }

    /// @notice the ```tryPauseRegisteredAddresses``` function tries to pause all registered swap addresses
    /// @param _setPaused the boolean value indicating whether to pause the registered swap addresses
    /// @return _successfulAddresses an array of the successful addresses
    /// @return _failedAddresses an array of the failed addresses
    function tryPauseRegisteredAddresses(
        bool _setPaused
    ) external returns (address[] memory _successfulAddresses, address[] memory _failedAddresses) {
        _requireIsRole({ _role: PAUSER_ROLE, _address: msg.sender });
        address[] memory _registeredSwapAddresses = _getPointerToAgoraStableSwapRegistryStorage()
            .registeredSwapAddresses
            .values();

        // instantiate the arrays to store the successful and failed addresses
        _successfulAddresses = new address[](_registeredSwapAddresses.length);
        _failedAddresses = new address[](_registeredSwapAddresses.length);

        for (uint256 i = 0; i < _registeredSwapAddresses.length; i++) {
            try IAgoraStableSwapPair(_registeredSwapAddresses[i]).setPaused(_setPaused) {
                _successfulAddresses[i] = (_registeredSwapAddresses[i]);
            } catch {
                _failedAddresses[i] = (_registeredSwapAddresses[i]);
            }
        }
    }
    //==============================================================================
    // View Functions
    //==============================================================================

    /// @notice the ```registeredSwapAddresses``` function returns the registered swap addresses
    /// @return _values an array of the registered swap addresses
    function registeredSwapAddresses() external view returns (address[] memory _values) {
        _values = _getPointerToAgoraStableSwapRegistryStorage().registeredSwapAddresses.values();
    }

    /// @notice the ```isRegisteredSwapAddress``` function checks if an address is registered
    /// @param _account the address to check
    /// @return _isRegistered the boolean value indicating whether the address is registered
    function isRegisteredSwapAddress(address _account) public view returns (bool _isRegistered) {
        _isRegistered = _getPointerToAgoraStableSwapRegistryStorage().registeredSwapAddresses.contains(_account);
    }

    /// @notice the ```registeredSwapAddressesLength``` function returns the length of the registered swap addresses
    /// @return _length the length of the registered swap addresses
    function registeredSwapAddressesLength() external view returns (uint256 _length) {
        _length = _getPointerToAgoraStableSwapRegistryStorage().registeredSwapAddresses.length();
    }

    /// @notice The ```version``` function returns the version of the AgoraStableSwapRegistry
    /// @return _version The version of the AgoraStableSwapRegistry
    function version() external view returns (Version memory _version) {
        _version = Version({ major: 1, minor: 0, patch: 0 });
    }

    //==============================================================================
    // Erc 7201: UnstructuredNamespace Storage Functions
    //==============================================================================

    /// @notice The ```AGORA_STABLE_SWAP_REGISTRY_STORAGE_SLOT``` is the storage slot for the AgoraStableSwapRegistryStorage struct
    /// @dev keccak256(abi.encode(uint256(keccak256("AgoraStableSwapRegistryStorage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant AGORA_STABLE_SWAP_REGISTRY_STORAGE_SLOT =
        0x9b38bf2bc0247ea992fca9acb8b0811b2a99a05f73d5535f284af3b75fea8e00;

    /// @notice The ```_getPointerToAgoraStableSwapRegistryStorage``` function returns a pointer to the AgoraStableSwapRegistryStorage struct
    /// @return $ A pointer to the AgoraStableSwapRegistryStorage struct
    function _getPointerToAgoraStableSwapRegistryStorage()
        internal
        pure
        returns (AgoraStableSwapRegistryStorage storage $)
    {
        /// @solidity memory-safe-assembly
        assembly {
            $.slot := AGORA_STABLE_SWAP_REGISTRY_STORAGE_SLOT
        }
    }

    //==============================================================================
    // Events
    //==============================================================================

    /// @notice the ```SwapAddressRegistered``` event is emitted when the swap address is registered
    /// @param _swapAddress the address of the swap that was registered
    event SwapAddressRegistered(address indexed _swapAddress);

    /// @notice the ```SwapAddressUnregistered``` event is emitted when the swap address is unregistered
    /// @param _swapAddress the address of the swap that was unregistered
    event SwapAddressUnregistered(address indexed _swapAddress);

    //==============================================================================
    // Errors
    //==============================================================================

    /// @notice the ```CallToRegisteredSwapAddressFailed``` error is emitted when the call to a registered swap address fails
    /// @param swapAddress the address of the swap that failed
    error CallToRegisteredSwapAddressFailed(address swapAddress);
}
