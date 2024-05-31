// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IFactory {
    function createExchange(address _tokenAddress) external returns (address);

    function getExchange(address _tokenAddress) external returns (address);
}
