// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/oz/ERC20.sol";
import "../lib/oz/IERC20.sol";

contract Exchange {
    uint256 liquidity;

    error lessTokensWhenSwapping();
    error lessEthWhenSwapping();

    constructor(address tokenA) {}

    function addLiquidity() public payable {
        if (getEthReserve() = 0) {} else {
            uint256 tokenAmount = (msg.value / getEthReserve()) *
                getTokenReserve();
            IERC20(tokenA).transferFrom(msg.sender, address(this), tokenAmount);
        }
    }

    function removeLiquidity() public payable {}
    // ^x*y/(x+^x) = ^y = amount of tokens

    function swapTokenToEth(int256 tokens, uint256 _minEth) public {
        IERC20(tokenA).transferFrom(msg.sender, address(this), tokens);
        uint256 ethAmount = getAmount(
            tokens,
            getTokenReserve(),
            getEthReserve()
        );

        if (ethAmount < _minEth) revert lessEthWhenSwapping();

        (bool sent, ) = payable(msg.sender).call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }

    function swapEthToToken(uint256 _minTokens) public payable {
        uint256 tokenAmount = getAmount(
            msg.value(),
            getEthReserve(),
            getTokenReserve()
        );
        if (tokenAmount < _minTokens) revert lessTokensWhenSwapping();
        IERC20(tokenA).transferFrom(address(this), msg.sender, tokenAmount);
    }

    function getAmount(
        uint256 amountIn,
        uint256 amountInReserve,
        uint256 amountOutReserve
    ) public pure returns (uint256 amount) {
        amount = (amountIn * amountOutReserve) / (amountIn + amountInReserve);
    }

    function getEthReserve() private view returns (uint256 ethAmount) {
        return balanceOf(address(this));
    }

    function getTokenReserve() private view returns (uint256 tokenAmount) {
        // return IERC20(tokenA).balanceOf(address(this));
    }
}
