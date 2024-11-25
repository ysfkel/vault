// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import "../interfaces/ISwapAdapter.sol";

contract UniswapAdapter is ISwapAdapter {
    
    function getTradeCalldata(bytes calldata data)
        external
        pure
        override
        returns (bytes memory, uint256)
    {
        // Decode the input data
        (address fromToken, address toToken, uint256 amountIn, uint256 amountOutMin, address to, uint256 deadline) = abi.decode(data, (address, address, uint256, uint256, address, uint256));

        // Generate the trade calldata for Uniswap
        bytes memory tradeCalldata = abi.encodeWithSignature(
            "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
            amountIn,
            amountOutMin,
            getPath(fromToken, toToken),
            to,
            deadline
        );

        // Return the trade calldata and value (0 for ERC20 token swaps)
        return (tradeCalldata, 0);
    }

    function getPath(address fromToken, address toToken) internal pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = fromToken;
        path[1] = toToken;
        return path;
    }
}