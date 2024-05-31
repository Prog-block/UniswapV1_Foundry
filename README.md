# UniswapV1🦄

Uniswap is a decentralized exchange (DEX). And thus aims to be an alternative to centralised exchanges. It is based on various smart contracts, which enable the exchange of tokens. Currently there are 3 versions of Uniswap. This repo deals with the first version i.e UniswapV1.

UniswapV1 introduced the concept of Automated Market Making (AMM) used Constant Product Market Maker Formula.

### Architecture Overview:

Exchange Contract: This is the main contract that facilitates token swaps. Users can exchange one ERC-20 token for another directly through this contract.

Factory Contract: This contract is responsible for deploying new Exchange Contracts for each token pair. It serves as a factory for creating new liquidity pools.

Token Contract: While Uniswap V1 doesn't have its own token, it interacts with ERC-20 tokens on the Ethereum blockchain. Users can swap any ERC-20 token listed on Uniswap.

## Usage

### Build 🏗️

```shell
$ forge build
```

### Test ✅

```shell
$ forge test --match-path test/Exchange.t.sol -vv
```

### Enjoy building✌️

