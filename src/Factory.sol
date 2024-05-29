// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Exchange} from "./Exchange.sol";

contract Factory {
    mapping(address => address) public tokenToExchange;
    error invalidTokenAddress();
    error exchangeExists();

    function createExchange(address _tokenAddress) public returns (address) {
        if (_tokenAddress == address(0)) revert invalidTokenAddress();
        if (tokenToExchange[_tokenAddress] != address(0))
            revert exchangeExists();

        Exchange exchange = new Exchange(_tokenAddress);
        tokenToExchange[_tokenAddress] = address(exchange);

        return address(exchange);
    }

    function getExchange(address _tokenAddress) public view returns (address) {
        return tokenToExchange[_tokenAddress];
    }
}
