// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Exchange} from "../src/Exchange.sol";

contract ExchangeTest is Test {
    Exchange public exchange;

    function setUp() public {
        exchange = new Exchange();
    }

    function test_AddLiquidity() public {
        
    }

    function testFuzz_SetNumber(uint256 x) public {}
}
