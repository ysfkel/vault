// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ISwapAdapter.sol";
import { GenericData } from  "../interfaces/IGenericSwapExactAmountIn.sol";

struct TradeData {
    address srcToken;
    address destToken;
    uint256 fromAmount;
    uint256 toAmount;
    uint256 quotedAmount;
    bytes32 metadata;
    address executor;
    uint256 partnerAndFee;
    bytes permit;
    bytes executorData;
} 

contract ParaswapAggregtorAdapter is ISwapAdapter {

    error ParaswapAggregtorAdapter__ZeroAmount();
 
    function getTradeCalldata(bytes calldata data) external view returns (bytes memory, uint256) {
        TradeData memory tradeData = abi.decode(data, (TradeData));

        if(tradeData.fromAmount == 0) revert ParaswapAggregtorAdapter__ZeroAmount();
        
        GenericData memory swapData = GenericData({
            srcToken: IERC20(tradeData.srcToken),
            destToken: IERC20(tradeData.destToken),
            fromAmount: tradeData.fromAmount,
            toAmount: tradeData.toAmount,
            quotedAmount: tradeData.quotedAmount, 
            metadata: tradeData.metadata, 
            beneficiary: payable(msg.sender)
        });

        bytes memory tradeCallData = abi.encodeWithSignature("swapExactAmountIn(address,(address,address,uint256,uint256,uint256,bytes32,address),uint256,bytes,bytes)",
        tradeData.executor,
        swapData ,  
        tradeData.partnerAndFee,
        tradeData.permit,
        tradeData.executorData);
    
        return (tradeCallData, 0); 

    }
}