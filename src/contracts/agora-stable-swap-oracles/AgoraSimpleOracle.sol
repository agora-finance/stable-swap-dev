// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IOracle } from "../agora-stable-swap-pair/AgoraStableSwapPairCore.sol";
import "forge-std/console.sol";

contract AgoraSimpleOracle is IOracle {
    uint256 public constant PRECISION = 1e18;

    address public admin;
    uint256 public price; //the price of the asset

    function initialize() public {
        admin = msg.sender;
    }

    function setPrice(uint256 _price) public {
        require(msg.sender == admin, "Caller is not the price setter");
        if (_price <= 0) revert("Invalid price");

        // Set the price of the asset
        price = _price;
    }

    function getPrice() external view returns (uint256) {
        return price;
    }
}
