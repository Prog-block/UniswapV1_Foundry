// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Exchange is ERC20 {
    address tokenAddress;

    error noTokenProvided();
    error noEtherProvided();
    error insufficientTokenAmount();
    error insufficientEtherAmount();

    constructor(address token) ERC20("UNISWAP-V1", "UNI-V1") {
        tokenAddress = token;
    }

    function addLiquidity(
        uint256 _minTokens
    ) public payable returns (uint256 liquidity) {
        if (getTokenReserve() == 0) {
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                _minTokens
            );
            liquidity = msg.value;
            _mint(msg.sender, liquidity);
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
            uint256 liquidity = (msg.value * totalSupply()) / ethReserve;
            _mint(msg.sender, liquidity);
        }
    }

    function removeLiquidity(
        uint256 _amount
    ) public payable returns (uint256 ethAmount, uint256 tokenAmount) {
        if (_amount == 0) revert noTokenProvided();

        ethAmount = (getEthReserve() * _amount) / totalSupply();
        tokenAmount = (getTokenReserve() * _amount) / totalSupply();

        IERC20(tokenAddress).transfer(ms.sender, tokenAmount);
        (bool sent, ) = payable(msg.sender).call{value: ethAmount}("");
        require(sent, "Failed to send Ether");
    }

    function swapTokenToEth(
        uint256 tokens,
        uint256 _minEth
    ) public returns (uint256 ethAmount) {
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokens);
        ethAmount = getAmount(tokens, getTokenReserve(), getEthReserve());

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

    // 0.3% fees
    // ^x*y/(x+^x) = ^y = amount of tokens
    function getAmount(
        uint256 amountIn,
        uint256 amountInReserve,
        uint256 amountOutReserve
    ) public pure returns (uint256 amount) {
        uint256 inputAmountWithFee = inputAmount * 997;
        amount =
            (inputAmountWithFee * amountOutReserve) /
            (inputAmountWithFee + amountInReserve * 1000);
    }

    function getEthReserve() public view returns (uint256 ethAmount) {
        ethAmount = address(this).balance;
    }

    function getTokenReserve() public view returns (uint256 tokenAmount) {
        tokenAmount = IERC20(tokenAddress).balanceOf(address(this));
    }
}
