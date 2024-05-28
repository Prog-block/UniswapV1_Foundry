// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Exchange} from "../src/Exchange.sol";
import {ERC20Mint} from "./ERC20_Mint.sol";

contract ExchangeTest is Test {
    Exchange exchange;
    ERC20Mint token;
    address alice = address(0x123);

    function setUp() public {
        token = new ERC20Mint("TOKEN", "TKN");
        token.mint(1e5 * 1e18, address(this));
        // token.mint(500 * 1e18, alice);

        assertEq(token.balanceOf(address(this)), 1e5 * 1e18);
        // assertEq(token.balanceOf(alice), 500 * 1e18);
        exchange = new Exchange(address(token));
    }

    function encodeError(
        string memory error
    ) internal pure returns (bytes memory encoded) {
        encoded = abi.encodeWithSignature(error);
    }

    receive() external payable {}

    function test_addLiquidity_initializingPool() public {
        token.approve(address(exchange), 1e5 * 1e18);

        address(exchange).call{value: 1e3 ether}(
            abi.encodeWithSignature("addLiquidity(uint256)", 1e4 * 1e18)
        );

        assertEq(token.balanceOf(address(this)), (1e5 - 1e4) * 1e18);
        assertEq(exchange.getTokenReserve(), 1e4 * 1e18);
        assertEq(exchange.getEthReserve(), 1e3 ether);
    }

    function test_addLiquidity_poolIsInitialized() public {
        test_addLiquidity_initializingPool();

        assertEq(token.balanceOf(address(this)), (1e5 - 1e4) * 1e18);
        assertEq(exchange.getTokenReserve(), 1e4 * 1e18);
        assertEq(exchange.getEthReserve(), 1e3 ether);

        token.approve(address(exchange), 1e4 * 1e18);
        address(exchange).call{value: 1e3 ether}(
            abi.encodeWithSignature("addLiquidity(uint256)", 1e4 * 1e18)
        );

        assertEq(token.balanceOf(address(this)), (9 * 1e4 - 1e4) * 1e18);
        assertEq(exchange.getTokenReserve(), (1e4 + 1e4) * 1e18);
        assertEq(exchange.getEthReserve(), 1e3 ether + 1e3 ether);
    }

    function test_swapTokenToEth() public {
        test_addLiquidity_initializingPool();
        exchange.swapTokenToEth(1e2 * 1e18, 8 * 1e18);

        assertEq(token.balanceOf(address(this)), (1e5 - 1e4 - 1e2) * 1e18);
        assertEq(exchange.getTokenReserve(), (1e4 + 1e2) * 1e18);
        assertEq(exchange.getEthReserve(), 1e3 ether - 9803921568627450980);
    }

    function test_RevertSwapTokenToEthWhen_insufficientEther() public {
        test_addLiquidity_initializingPool();

        vm.expectRevert(encodeError("insufficientEtherAmount()"));
        exchange.swapTokenToEth(1e2 * 1e18, 10 * 1e18);
    }

    function test_swapEthToToken() public {
        test_addLiquidity_initializingPool();
        address(exchange).call{value: 10 * 1e18}(
            abi.encodeWithSignature("swapEthToToken(uint256)", 95 * 1e18)
        );

        assertEq(
            token.balanceOf(address(this)),
            (1e5 - 1e4) * 1e18 + 99009900990099009900
        );
        assertEq(
            exchange.getTokenReserve(),
            (1e4) * 1e18 - 99009900990099009900
        );
        assertEq(exchange.getEthReserve(), 1e3 ether + 10 ether);
    }

    function test_RevertSwapEthToTokenWhen_insufficientToken() public {
        test_addLiquidity_initializingPool();

        vm.expectRevert(encodeError("insufficientTokenAmount()"));
        address(exchange).call{value: 10 * 1e18}(
            abi.encodeWithSignature("swapEthToToken(uint256)", 100 * 1e18)
        );
    }

    
}

// forge test --match-path test/Exchange.t.sol -vvv
// cd UniswapV1_Foundry
