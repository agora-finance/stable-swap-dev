// SPDX-License-Identifier: ISC
pragma solidity ^0.8.28;

import { AgoraStableSwapRegistryAccessControl } from "./AgoraStableSwapRegistryAccessControl.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract AgoraStableSwapRegistry is Initializable, AgoraStableSwapRegistryAccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice a set of the current registered swap addresses
    struct AgoraStableSwapRegistryStorage {
        EnumerableSet.AddressSet registeredSwapAddresses;
    }

    //==============================================================================
    // Initialization Function
    //==============================================================================

    constructor() {
        _disableInitializers();
    }

    function initialize(address _initialAdminAddress) external initializer {
        _initializeAgoraStableSwapRegistryAccessControl({ _initialAdminAddress: _initialAdminAddress });
    }

    //==============================================================================
    // External Stateful Functions
    //==============================================================================

    /// @notice the ```registerSwapAddress``` function registers a swap address
    /// @param _swapAddress the address of the swap to register
    function setSwapAddress(address _swapAddress, bool _isRegistered) external {
        _requireSenderIsRole({ _role: ADMIN_ROLE });
        if (_isRegistered) _getPointerToAgoraStableSwapRegistryStorage().registeredSwapAddresses.add(_swapAddress);
        else _getPointerToAgoraStableSwapRegistryStorage().registeredSwapAddresses.remove(_swapAddress);
    }

    function executeOnRegisteredAddresses(bytes calldata _data) external {
        _requireSenderIsRole({ _role: ADMIN_ROLE });
        address[] memory _registeredSwapAddresses = _getPointerToAgoraStableSwapRegistryStorage()
            .registeredSwapAddresses
            .values();
        for (uint256 i = 0; i < _registeredSwapAddresses.length; i++) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = _registeredSwapAddresses[i].call(_data);
            if (!success) revert CallToRegisteredSwapAddressFailed(_registeredSwapAddresses[i]);
        }
    }

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

    function tryWhitelistUserOnRegisteredAddresses(
        address _address,
        bool _isApproved
    ) external returns (address[] memory _successfulAddresses, address[] memory _failedAddresses) {
        _requireIsRole({ _role: WHITELISTER_ROLE, _address: msg.sender });
        address[] memory _registeredSwapAddresses = _getPointerToAgoraStableSwapRegistryStorage()
            .registeredSwapAddresses
            .values();

        // get the call data for the whitelist function
        bytes[] memory _callDataArray = new bytes[](_registeredSwapAddresses.length);
        for (uint256 i = 0; i < _registeredSwapAddresses.length; i++) {
            bytes memory setApprovedCallData = abi.encodeWithSignature(
                "setApprovedSwapper(address, bool)",
                _address,
                _isApproved
            );
            _callDataArray[i] = setApprovedCallData;
        }
        // instantiate the arrays to store the successful and failed addresses
        _successfulAddresses = new address[](_registeredSwapAddresses.length);
        _failedAddresses = new address[](_registeredSwapAddresses.length);

        for (uint256 i = 0; i < _registeredSwapAddresses.length; i++) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = _registeredSwapAddresses[i].call(_callDataArray[i]);
            if (!success) _failedAddresses[i] = (_registeredSwapAddresses[i]);
            else _successfulAddresses[i] = (_registeredSwapAddresses[i]);
        }
    }

    //==============================================================================
    // View Functions
    //==============================================================================

    function registeredSwapAddresses() external view returns (address[] memory _values) {
        _values = _getPointerToAgoraStableSwapRegistryStorage().registeredSwapAddresses.values();
    }

    function isRegisteredSwapAddress(address _account) public view returns (bool _isRegistered) {
        _isRegistered = _getPointerToAgoraStableSwapRegistryStorage().registeredSwapAddresses.contains(_account);
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

    error CallToRegisteredSwapAddressFailed(address swapAddress);
}
