// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// addLiquidity , remove liquidity ,

interface IExchange {
    function swapEthToToken(uint256 _minTokens) external payable;

    function ethToTokenTransfer(
        uint256 _minTokens,
        address _recipient
    ) external payable;
}
