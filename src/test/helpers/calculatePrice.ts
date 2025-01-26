import { Decimal } from "decimal.js";
import { encodeAbiParameters } from "viem";

// Set large precision and rounding mode to match Solidity's default
Decimal.set({ precision: 64, rounding: Decimal.ROUND_DOWN });

// import cli args
const args = process.argv.slice(2);
const lastUpdated = new Decimal(args[0]);
const currentTimestamp = new Decimal(args[1]);
const interestRate = new Decimal(args[2]).dividedBy(1e18);
const basePrice = new Decimal(args[3]).dividedBy(1e18);

const timeElapsed = currentTimestamp.minus(lastUpdated);
const valueRaw = basePrice.times(new Decimal(1).plus(interestRate.times(timeElapsed)));
const value = valueRaw.times(1e18);
// console.log("value:", BigInt(value.toFixed(0)));

const abiEncodedValue = encodeAbiParameters([{ type: "uint256" }], [BigInt(value.toFixed(0))]);
console.log(abiEncodedValue);
