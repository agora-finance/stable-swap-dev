// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IOracle } from "../agora-stable-swap-pair/AgoraStableSwapPairCore.sol";
import "forge-std/console.sol";

contract AgoraCompoundingOracle is IOracle {
    uint256 public constant PRECISION = 1e18;

    /// @notice the admin address (price setter)
    address public admin;

    /// @notice the compounding factor
    /// @dev the compounding factor is simple interest (APR) per second
    uint256 public compoundingFactor;
    /// @notice the time of the last price update
    uint256 public lastSetTime;
    /// @notice the base price of the asset
    uint256 public price;

    function initialize() public {
        lastSetTime = block.timestamp;
        admin = msg.sender;
    }

    function setCompoundingPrice(uint256 _basePrice, uint256 _yearlyApr) public {
        require(msg.sender == admin, "Caller is not the price setter");
        if ((_basePrice <= 0) || (_yearlyApr <= 0)) revert("Invalid price or APR");

        // Set the time of the last price update
        lastSetTime = block.timestamp;
        // Convert yearly APR to per second APR
        compoundingFactor = _yearlyApr / 365 days;
        // Set the price of the asset
        price = _basePrice;
    }

    function getPrice() external view returns (uint256) {
        // Calculate the time elapsed since the last price update
        uint256 timeElapsed = block.timestamp - lastSetTime;
        // Calculate the compounded price
        return (price + (compoundingFactor * timeElapsed));
    }
}
