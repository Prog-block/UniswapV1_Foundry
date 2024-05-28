// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Exchange {
    uint256 liquidity;
    address tokenAddress;

    error noTokenProvided();
    error noEtherProvided();
    error insufficientTokenAmount();
    error insufficientEtherAmount();

    constructor(address token) {
        tokenAddress = token;
    }

    function addLiquidity(uint256 _minTokens) public payable {
        if (getTokenReserve() == 0) {
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                _minTokens
            );
        } else {
            uint256 ethReserve = getEthReserve() - msg.value;
            uint256 tokenAmount = (msg.value * getTokenReserve()) /
                (ethReserve);
            if (_minTokens < tokenAmount) revert insufficientTokenAmount();

            IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                tokenAmount
            );
        }
    }

    function removeLiquidity() public payable {}

    // ^x*y/(x+^x) = ^y = amount of tokens

    function swapTokenToEth(uint256 tokens, uint256 _minEth) public {
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokens);
        uint256 ethAmount = getAmount(
            tokens,
            getTokenReserve(),
            getEthReserve()
        );

        if (ethAmount < _minEth) revert insufficientEtherAmount();

        (bool sent, ) = payable(msg.sender).call{value: ethAmount}("");
        require(sent, "Failed to send Ether");
    }

    function swapEthToToken(
        uint256 _minTokens
    ) public payable returns (uint256 tokenAmount) {
        uint256 tokenAmount = getAmount(
            msg.value,
            getEthReserve() - msg.value,
            getTokenReserve()
        );
        if (tokenAmount < _minTokens) revert insufficientTokenAmount();
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
    }

    function getAmount(
        uint256 amountIn,
        uint256 amountInReserve,
        uint256 amountOutReserve
    ) public pure returns (uint256 amount) {
        amount = (amountIn * amountOutReserve) / (amountIn + amountInReserve);
    }

    function getEthReserve() public view returns (uint256 ethAmount) {
        return address(this).balance;
    }

    function getTokenReserve() public view returns (uint256 tokenAmount) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }
}
