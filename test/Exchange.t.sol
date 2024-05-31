// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Exchange} from "../src/Exchange.sol";
import {ERC20Mint} from "./ERC20_Mint.sol";

contract ExchangeTest is Test {
    Exchange exchange;
    ERC20Mint token;

    // address alice = address(0x123);

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

    function assertReserves(
        uint256 tokenBalanceOfTest,
        uint256 tokenBalanceOfExchange,
        uint256 ethBalanceOfExchange
    ) internal {
        assertEq(
            token.balanceOf(address(this)),
            tokenBalanceOfTest,
            "unexpected token reserve of test"
        );
        assertEq(
            exchange.getTokenReserve(),
            tokenBalanceOfExchange,
            "unexpected token reserve of pool"
        );
        assertEq(
            exchange.getEthReserve(),
            ethBalanceOfExchange,
            "unexpected eth reserve of pool"
        );
    }

    receive() external payable {}

    function test_addLiquidity_initializingPool() public {
        token.approve(address(exchange), 1e5 * 1e18);

        address(exchange).swapEthToToken(){value: 1e3 ether}(1e4 * 1e18);
        assertReserves((1e5 - 1e4) * 1e18, 1e4 * 1e18, 1e3 ether);
        assertEq(exchange.balanceOf(address(this)), 1e3 ether);
        assertEq(exchange.totalSupply(), 1e3 ether);
    }

    function test_addLiquidity_whenTheresLiquidity() public {
        test_addLiquidity_initializingPool();

        token.approve(address(exchange), 1e4 * 1e18);
        address(exchange).swapEthToToken(){value: 1e3 ether}(1e4 * 1e18);
        assertReserves(
            (9 * 1e4 - 1e4) * 1e18,
            (1e4 + 1e4) * 1e18,
            1e3 ether + 1e3 ether
        );
        assertEq(exchange.balanceOf(address(this)), 1e3 ether + 1e3 ether);
        assertEq(exchange.totalSupply(), 1e3 ether + 1e3 ether);
    }

    function test_removeLiquidity() public {
        test_addLiquidity_initializingPool();

        exchange.removeLiquidity(100);
        assertReserves(1e5 - 1e4 + 1000, 1e4 - 1000, 1000 - 100);
    }

    function test_RevertRemoveLiquidityWhen_removeZeroLiquidity() public {
        test_addLiquidity_initializingPool();
        vm.expectRevert(encodeError("NoTokenProvided()"));
        exchange.removeLiquidity(0);
    }

    function test_swapTokenToEth() public {
        test_addLiquidity_initializingPool();
        exchange.swapTokenToEth(1e2 * 1e18, 8 * 1e18);
        assertReserves(
            (1e5 - 1e4 - 1e2) * 1e18,
            (1e4 + 1e2) * 1e18,
            (997 * (1e3 ether - 9803921568627450980)) / 1000
        );
    }

    function test_RevertSwapTokenToEthWhen_zeroTokens() public {
        test_addLiquidity_initializingPool();

        vm.expectRevert(encodeError("NoTokenProvided()"));
        exchange.swapTokenToEth(0, 1 * 1e18);
    }

    function test_RevertSwapTokenToEthWhen_insufficientEther() public {
        test_addLiquidity_initializingPool();

        vm.expectRevert(encodeError("insufficientEtherAmount()"));
        exchange.swapTokenToEth(1e2 * 1e18, 10 * 1e18);
    }

    function test_swapEthToToken() public {
        test_addLiquidity_initializingPool();

        address(exchange).swapEthToToken(){value: 10 ether}(95 * 1e18);
        assertReserves(
            (1e5 - 1e4) * 1e18 + (997 * (99009900990099009900)) / 1000,
            (1e4) * 1e18 - (997 * (99009900990099009900)) / 1000,
            1e3 ether + 10 ether
        );
    }

    function test_RevertSwapEthToTokenWhen_zeroEther() public {
        test_addLiquidity_initializingPool();

        vm.expectRevert(encodeError("NoEtherProvided()"));
        address(exchange).swapEthToToken(){value: 0}(100 * 1e18);
    }

    function test_RevertSwapEthToTokenWhen_insufficientToken() public {
        test_addLiquidity_initializingPool();

        vm.expectRevert(encodeError("insufficientTokenAmount()"));
        address(exchange).swapEthToToken(){value: 10 * 1e18}(100 * 1e18);
    }
}

// forge test --match-path test/Exchange.t.sol -vvv
// cd UniswapV1_Foundry
