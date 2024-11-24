// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import { IGenericSwapExactAmountIn,IErrors,GenericData  } from "../protocol/interfaces/IGenericSwapExactAmountIn.sol";


contract MockGenericSwapExactAmountIn is IGenericSwapExactAmountIn {
  

    uint256 _receivedAmount;
    uint256 _paraswapShare;
    uint256 _partnerShare;
    constructor(uint256 __receivedAmount, uint256 __paraswapShare, uint256 __partnerShare) {
      _receivedAmount = __receivedAmount;
      _paraswapShare = __paraswapShare;
      _partnerShare = __partnerShare;
    }


    function swapExactAmountIn( address,  GenericData memory, uint256, bytes memory, bytes memory) external payable returns (uint256 receivedAmount, uint256 paraswapShare, uint256 partnerShare) {

       return (
        _receivedAmount,
        _paraswapShare,
        _partnerShare
       );
    }
}
