// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IExchange.sol";
import "./interfaces/IFactory.sol";

contract Exchange is ERC20 {
    address public tokenAddress;
    address public factoryAddress;

    error invalidExchangeAddress();
    error InvalidTokenAddress();
    error noTokenProvided();
    error noEtherProvided();
    error insufficientTokenAmount();
    error insufficientEtherAmount();
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

            if (tokenAmount < _tokenAmount) revert insufficientTokenAmount();

            _safeTransferToken(msg.sender, address(this), tokenAmount);
            liquidity = (msg.value * totalSupply()) / ethReserve;
            _mint(msg.sender, liquidity);
        }
    }

    function removeLiquidity(
        uint256 _amount
    ) public payable returns (uint256 ethAmount, uint256 tokenAmount) {
        if (_amount == 0) revert noTokenProvided();

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
        if (_amount == 0) revert noTokenProvided();
        _safeTransferToken(msg.sender, address(this), _amount);
        ethAmount = getAmount(_amount, getTokenReserve(), getEthReserve());

        if (ethAmount < _minEth) revert insufficientEtherAmount();
        _safeTransferEth(msg.sender, ethAmount);
    }

    function ethToTokenTransfer(
        uint256 _minTokens,
        address _recipient
    ) public payable {
        if (msg.value == 0) revert noEtherProvided();
        ethToToken(_minTokens, _recipient);
    }

    function swapEthToToken(
        uint256 _minAmount
    ) public payable returns (uint256 tokenAmount) {
        if (msg.value == 0) revert noEtherProvided();

        ethToToken(_minAmount, msg.sender);
    }

    function ethToToken(
        uint256 _minAmount,
        address recipient
    ) private returns (uint256 tokenAmount) {
        tokenAmount = getAmount(
            msg.value,
            getEthReserve() - msg.value,
            getTokenReserve()
        );
        if (tokenAmount < _minAmount) revert insufficientTokenAmount();
        IERC20(tokenAddress).transfer(recipient, tokenAmount);
    }

    function swapTokenToToken(
        uint256 _tokenInAmount,
        uint256 _minTokenOutAmount,
        address _tokenAddress
    ) public payable returns (uint256 tokenAmount) {
        if (_tokenInAmount == 0) revert noTokenProvided();
        if (_tokenAddress == 0) revert InvalidTokenAddress();

        address exchangeAddress = IFactory(factoryAddress).getExchange(
            _tokenAddress
        );
        if (exchangeAddress == address(this) || exchangeAddress == address(0))
            revert invalidExchangeAddress();

        uint256 ethBought = getAmount(
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
    function getAmount(
        uint256 amountIn,
        uint256 amountInReserve,
        uint256 amountOutReserve
    ) private pure returns (uint256 amount) {
        uint256 inputAmountWithFee = amountIn * 997;
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

    function _safeTransferEth(address to, uint256 value) private {
        (bool sent, bytes memory data) = payable(to).call{value: value}("");

        if (!success || (data.length != 0 && !abi.decode(data, (bool))))
            revert TransferFailed();
    }

    function _safeTransferToken(
        address from,
        address to,
        uint256 amount
    ) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                from,
                to,
                value
            )
        );
        if (!success || (data.length != 0 && !abi.decode(data, (bool))))
            revert TransferFailed();
    }
}
