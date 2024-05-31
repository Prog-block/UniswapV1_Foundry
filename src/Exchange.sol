// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IExchange} from "./interfaces/IExchange.sol";
import {IFactory} from "./interfaces/IFactory.sol";

contract Exchange is ERC20 {
    address public tokenAddress;
    address public factoryAddress;

    error InvalidExchangeAddress();
    error InvalidTokenAddress();
    error NoTokenProvided();
    error NoEtherProvided();
    error InsufficientTokenAmount();
    error InsufficientEtherAmount();
    error TransferFailed();

    constructor(address token) ERC20("UNISWAP-V1", "UNI-V1") {
        if (tokenAddress == address(0)) revert InvalidTokenAddress();
        factoryAddress = msg.sender;
        tokenAddress = token;
    }

    function addLiquidity(
        uint256 _tokenAmount
    ) public payable returns (uint256 liquidity) {
        if (getTokenReserve() == 0) {
            _safeTransferToken(msg.sender, address(this), _tokenAmount);

            liquidity = msg.value;
            _mint(msg.sender, liquidity);
        } else {
            uint256 ethReserve = getEthReserve() - msg.value;
            uint256 tokenAmount = (msg.value * getTokenReserve()) /
                (ethReserve);

            if (tokenAmount < _tokenAmount) revert InsufficientTokenAmount();

            _safeTransferToken(msg.sender, address(this), tokenAmount);
            liquidity = (msg.value * totalSupply()) / ethReserve;
            _mint(msg.sender, liquidity);
        }
    }

    function removeLiquidity(
        uint256 _amount
    ) public payable returns (uint256 ethAmount, uint256 tokenAmount) {
        if (_amount == 0) revert NoTokenProvided();

        ethAmount = (getEthReserve() * _amount) / totalSupply();
        tokenAmount = (getTokenReserve() * _amount) / totalSupply();
        _burn(msg.sender, _amount);
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
        _safeTransferEth(msg.sender, ethAmount);
    }

    function swapTokenToEth(
        uint256 _amount,
        uint256 _minEth
    ) public returns (uint256 ethAmount) {
        if (_amount == 0) revert NoTokenProvided();
        _safeTransferToken(msg.sender, address(this), _amount);
        ethAmount = _getAmount(_amount, getTokenReserve(), getEthReserve());

        if (ethAmount < _minEth) revert InsufficientEtherAmount();
        _safeTransferEth(msg.sender, ethAmount);
    }

    function _ethToTokenTransfer(
        uint256 _minTokens,
        address _recipient
    ) public payable returns (uint256 tokenAmount) {
        if (msg.value == 0) revert NoEtherProvided();
        tokenAmount = _ethToToken(_minTokens, _recipient);
    }

    function swapEthToToken(
        uint256 _minAmount
    ) public payable returns (uint256 tokenAmount) {
        if (msg.value == 0) revert NoEtherProvided();

        tokenAmount = _ethToToken(_minAmount, msg.sender);
    }

    function _ethToToken(
        uint256 _minAmount,
        address recipient
    ) private returns (uint256 tokenAmount) {
        tokenAmount = _getAmount(
            msg.value,
            getEthReserve() - msg.value,
            getTokenReserve()
        );
        if (tokenAmount < _minAmount) revert InsufficientTokenAmount();
        IERC20(tokenAddress).transfer(recipient, tokenAmount);
    }

    function swapTokenToToken(
        uint256 _tokenInAmount,
        uint256 _minTokenOutAmount,
        address _tokenAddress
    ) public payable {
        if (_tokenInAmount == 0) revert NoTokenProvided();
        if (_tokenAddress == address(0)) revert InvalidTokenAddress();

        address exchangeAddress = IFactory(factoryAddress).getExchange(
            _tokenAddress
        );
        if (exchangeAddress == address(this) || exchangeAddress == address(0))
            revert InvalidExchangeAddress();

        uint256 ethBought = _getAmount(
            _tokenInAmount,
            getTokenReserve(),
            getEthReserve()
        );

        _safeTransferToken(msg.sender, address(this), _tokenInAmount);
        IExchange(exchangeAddress).ethToTokenTransfer{value: ethBought}(
            _minTokenOutAmount,
            msg.sender
        );
    }

    // 0.3% fees
    // ^x*y/(x+^x) = ^y = amount of tokens
    function _getAmount(
        uint256 amountIn,
        uint256 amountInReserve,
        uint256 amountOutReserve
    ) private pure returns (uint256 amount) {
        assembly {
            let inputAmountWithFee := mul(amountIn, 997) // 1000 gas savings at each execution
            amount := div(
                mul(inputAmountWithFee, amountOutReserve),
                add(inputAmountWithFee, mul(amountInReserve, 1000))
            )
        }
        //     uint256 inputAmountWithFee = amountIn * 997;
        //     amount =
        //         (inputAmountWithFee * amountOutReserve) /
        //         (inputAmountWithFee + amountInReserve * 1000);
    }

    function getEthReserve() public view returns (uint256 ethAmount) {
        ethAmount = address(this).balance;
    }

    function getTokenReserve() public view returns (uint256 tokenAmount) {
        tokenAmount = IERC20(tokenAddress).balanceOf(address(this));
    }

    function _safeTransferEth(address to, uint256 value) private {
        (bool success, bytes memory data) = payable(to).call{value: value}("");

        if (!success || (data.length != 0 && !abi.decode(data, (bool))))
            revert TransferFailed();
    }

    function _safeTransferToken(
        address from,
        address to,
        uint256 amount
    ) private {
        (bool success, bytes memory data) = tokenAddress.call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                from,
                to,
                amount
            )
        );
        if (!success || (data.length != 0 && !abi.decode(data, (bool))))
            revert TransferFailed();
    }
}
