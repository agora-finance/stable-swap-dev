
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract AgoraTransparentUpgradeableProxy is ERC1967Proxy {

    address private immutable _admin;

    /**
     * @dev The proxy caller is the current admin, and can't fallback to the proxy target.
     */
    error ProxyDeniedAdminAccess();

    /**
     * @dev Initializes an upgradeable proxy managed by an instance of a {AgoraProxyAdmin} with an `initialOwner`,
     * backed by the implementation at `_logic`, and optionally initialized with `_data` as explained in
     * {ERC1967Proxy-constructor}.
     */
    constructor(address _logic, address _proxyAdminAddress, bytes memory _data) payable ERC1967Proxy(_logic, _data) {
        _admin = _proxyAdminAddress;
        // Set the storage value and emit an event for ERC-1967 compatibility
        ERC1967Utils.changeAdmin(_admin);
    }

    /**
     * @dev If caller is the admin process the call internally, otherwise transparently fallback to the proxy behavior.
     */
    function _fallback() internal virtual override {
        if (msg.sender == _admin) {
            if (msg.sig != ITransparentUpgradeableProxy.upgradeToAndCall.selector) {
                revert ProxyDeniedAdminAccess();
            } else {
                (address newImplementation, bytes memory data) = abi.decode(msg.data[4:], (address, bytes));
                ERC1967Utils.upgradeToAndCall(newImplementation, data);
            }
        } else {
            super._fallback();
        }   
    }
}
