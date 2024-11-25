// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

interface ISwapAdapter {
    function getTradeCalldata(bytes calldata tradeData)
        external
        view
        returns (bytes memory tradeCallData, uint256 value);
}