// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Struct containg data for generic swapExactAmountIn/swapExactAmountOut
/// @param srcToken The token to swap from
/// @param destToken The token to swap to
/// @param fromAmount The amount of srcToken to swap
/// = amountIn for swapExactAmountIn and maxAmountIn for swapExactAmountOut
/// @param toAmount The minimum amount of destToken to receive
/// = minAmountOut for swapExactAmountIn and amountOut for swapExactAmountOut
/// @param quotedAmount The quoted expected amount of destToken/srcToken
/// = quotedAmountOut for swapExactAmountIn and quotedAmountIn for swapExactAmountOut
/// @param metadata Packed uuid and additional metadata
/// @param beneficiary The address to send the swapped tokens to
struct GenericData {
    IERC20 srcToken;
    IERC20 destToken;
    uint256 fromAmount;
    uint256 toAmount;
    uint256 quotedAmount;
    bytes32 metadata;
    address payable beneficiary;
}

/// @title IErrors
/// @notice Common interface for errors
interface IErrors {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the returned amount is less than the minimum amount
    error InsufficientReturnAmount();

    /// @notice Emitted when the specified toAmount is less than the minimum amount (2)
    error InvalidToAmount();
}

/// @title IGenericSwapExactAmountIn
/// @notice Interface for executing a generic swapExactAmountIn through an Augustus executor
interface IGenericSwapExactAmountIn is IErrors {
    /*//////////////////////////////////////////////////////////////
                          SWAP EXACT AMOUNT IN
    //////////////////////////////////////////////////////////////*/

    /// @notice Executes a generic swapExactAmountIn using the given executorData on the given executor
    /// @param executor The address of the executor contract to use
    /// @param swapData Generic data containing the swap information
    /// @param partnerAndFee packed partner address and fee percentage, the first 12 bytes is the feeData and the last
    /// 20 bytes is the partner address
    /// @param permit The permit data
    /// @param executorData The data to execute on the executor
    /// @return receivedAmount The amount of destToken received after fees
    /// @return paraswapShare The share of the fees for Paraswap
    /// @return partnerShare The share of the fees for the partner
    function swapExactAmountIn( address executor, GenericData calldata swapData, uint256 partnerAndFee, bytes calldata permit, bytes calldata executorData) external payable returns (uint256 receivedAmount, uint256 paraswapShare, uint256 partnerShare);
}
