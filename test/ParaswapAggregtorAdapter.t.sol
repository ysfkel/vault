// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import {Test, console} from "forge-std/Test.sol";
import "@openzeppelin-upgrades/Upgrades.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import { Token } from "../mock/Token.sol"; 
import "../protocol/adapters/ParaswapAggregtorAdapter.sol";
import "../protocol/adapters/UniswapAdapter.sol";
import "../protocol/interfaces/ISwapAdapter.sol";
import "../mock/MockGenericSwapExactAmountIn.sol";
import "../protocol/interfaces/IGenericSwapExactAmountIn.sol";

contract VaultTest is Test {
    using Address for address;

    Token underlyingAsset;
    Token destToken;
     address USER1 =  makeAddr("USER1");
     address ADMIN_USER =  makeAddr("ADMIN_USER");
     address WITHDRAW_USER =  makeAddr("WITHDRAW_USER");
     address TRADER_USER =  makeAddr("TRADER_USER");
     address executor = makeAddr("EXECUTOR");
     address fakeParaswap = makeAddr("_fakeParaswap");
     ISwapAdapter  paraswapAdapter;
     ISwapAdapter uniswapAdapter;
     MockGenericSwapExactAmountIn paraswap;

    function setUp() public { 
       underlyingAsset  = new Token(); 
       destToken  = new Token(); 
       uniswapAdapter = new UniswapAdapter();
       paraswapAdapter = new ParaswapAggregtorAdapter(); 
 
    }

   function test_adapter() public {

      uint256 fromAmount = 200 ether;
      uint256 toAmount = 150 ether;
      uint256 quotedAmount = 150 ether; 

      vm.startBroadcast(TRADER_USER);
      TradeData memory tradeData = TradeData({
          srcToken: address(underlyingAsset),
          destToken: address(destToken),
          fromAmount:fromAmount,
          toAmount:toAmount,
          quotedAmount: quotedAmount,
          metadata: keccak256("metadata"),
          executor:executor,
          partnerAndFee: 3,
          permit: bytes("permit"),
          executorData:  bytes("executorData")
      });
      
      bytes memory encodedTradeData = abi.encode(tradeData);

     (bytes memory tradeCallData, uint256 value) = paraswapAdapter.getTradeCalldata(encodedTradeData);
  
    (address _executor, GenericData memory swapData , uint256 _partnerAndFee, bytes memory _permit, bytes memory _executorData, bytes4 _functionSelector) = decodeTradeCallData(tradeCallData);
   
     assertEq(_executor, executor);
     assertEq(_partnerAndFee, 3);
     assertEq(address(swapData.srcToken), address(underlyingAsset));
     assertEq(address(swapData.destToken), address(destToken));
     assertEq(swapData.fromAmount, 200 ether);
     assertEq(swapData.toAmount, 150 ether);
     assertEq(swapData.quotedAmount, 150 ether);
     assertEq(swapData.metadata, keccak256("metadata"));
     assertEq(_partnerAndFee, 3);
     assertEq(_permit, bytes("permit"));
     assertEq(_executorData, bytes("executorData"));
     assertEq(_functionSelector, bytes4(keccak256("swapExactAmountIn(address,(address,address,uint256,uint256,uint256,bytes32,address),uint256,bytes,bytes)")));

    MockGenericSwapExactAmountIn _paraswap = new MockGenericSwapExactAmountIn(200, 3,5);
    (bytes memory returnData) = address(_paraswap).functionCallWithValue(tradeCallData, value); 
    (uint256 receivedAmount, uint256 paraswapShare, uint256 partnerShare) = abi.decode(returnData, (uint256, uint256, uint256));
    assertEq(receivedAmount, 200);
    assertEq(paraswapShare, 3);
    assertEq(partnerShare, 5);
    vm.stopBroadcast();
   }

   function decodeTradeCallData(bytes memory tradeCallData) public pure returns (
    address _executor,
    GenericData memory swapData,
    uint256 partnerAndFee,
    bytes memory permit,
    bytes memory executorData,
    bytes4 functionSelector
) {
    // Use inline assembly to skip the first 4 bytes (function selector)
    assembly {

        functionSelector := and(mload(add(tradeCallData, 32)), 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        tradeCallData := add(tradeCallData, 4)
    } 

    // Decode the remaining data
    (_executor, swapData, partnerAndFee, permit, executorData) = abi.decode(tradeCallData, (address, GenericData, uint256, bytes, bytes));

}
 
}

