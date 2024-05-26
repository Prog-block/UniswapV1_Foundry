// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// addLiquidity , remove liquidity ,

interface IExchange {
    function addLiquidity(
        uint256 _minTokens
    ) external payable returns (uint256 tokensAdded);

    function getEthReserve() external view returns (uint256 ethAmount);
    function getTokenReserve() external view returns (uint256 tokenAmount);

    function removeLiquidity(
        uint256 LPTokens
    ) external returns (uint256 tokensRemoved, uint256 EthersRemoved);

    function swapTokenToEthers(
        uint256 amoountOfTokens
    ) external returns (uint256 amoountOfEthers);

    function swapEthersToTokens()
        external
        payable
        returns (uint256 amoountOfTokens);
}
