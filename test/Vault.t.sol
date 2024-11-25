// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import {Test, console} from "forge-std/Test.sol";
import "@openzeppelin-upgrades/Upgrades.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";
import { Vault } from "../protocol/Vault.sol";
import { Token } from "../mock/Token.sol";
import "../protocol/adapters/ParaswapAggregtorAdapter.sol";
import "../protocol/interfaces/ISwapAdapter.sol";
import "../mock/MockGenericSwapExactAmountIn.sol";

contract VaultTest is Test {
   bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    Vault public vault;
    Token underlyingAsset;
    Token destToken;
     address USER1 =  makeAddr("USER1");
     address ADMIN_USER =  makeAddr("ADMIN_USER");
     address WITHDRAW_USER =  makeAddr("WITHDRAW_USER");
     address TRADER_USER =  makeAddr("TRADER_USER");
     address executor = makeAddr("EXECUTOR"); 
     address fakeAdapter = makeAddr("FAKE_ADAPTER"); 

     ISwapAdapter  paraswapAdapter;
     MockGenericSwapExactAmountIn paraswap;
    function setUp() public { 
       underlyingAsset  = new Token(); 
       destToken  = new Token(); 
       paraswapAdapter = new ParaswapAggregtorAdapter(); 
       paraswap = new MockGenericSwapExactAmountIn(200, 3,5);
       address proxy = Upgrades.deployUUPSProxy("Vault.sol",abi.encodeCall(Vault.initialize, ("Test Vault","TV", address(underlyingAsset),
       address(paraswap), address(paraswapAdapter))));
       vault =  Vault(proxy);
       vault.grantRole(vault.WITHDRAW_ROLE(), WITHDRAW_USER);
       vault.grantRole(vault.TRADER_ROLE(), TRADER_USER);
    }

    function test_constructor() public view {
       vm.assertEq(address(vault.asset()), address(underlyingAsset));
       vm.assertEq(address(vault.getAggregatorAdapter(address(paraswap))), address(paraswapAdapter));
    }

    function test_deposit_reverts_with__Vault__ZeroAmount() public { 
        vm.expectRevert(Vault.Vault__ZeroAmount.selector);
        vault.deposit(0);
     } 

    function test_deposit_succeeds() public { 
       vm.startBroadcast(USER1);
       uint256 mintAmount = 100*10**18;
       underlyingAsset.mint(USER1, mintAmount);
       underlyingAsset.approve(address(vault), mintAmount);
       vault.deposit(mintAmount);
       assertEq(underlyingAsset.balanceOf(address(vault)),mintAmount);
       assertEq(underlyingAsset.balanceOf(USER1),0);
       vm.stopBroadcast();
    }

    function test_withdraw_reverts_with__AccessControlUnauthorizedAccount() public { 
      vm.startBroadcast(USER1);
      vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, USER1, vault.WITHDRAW_ROLE()));
      vault.withdraw(0, USER1);
      vm.stopBroadcast();
   }
    
   function test_withdraw_reverts_with__Vault__ZeroAmount() public { 
      vm.startBroadcast(WITHDRAW_USER);
      vm.expectRevert(Vault.Vault__ZeroAmount.selector);
      vault.withdraw(0, WITHDRAW_USER);
      vm.stopBroadcast();
   }

   function test_withdraw_reverts_with__Vault__ZeroAddress() public { 
      vm.startBroadcast(WITHDRAW_USER);
      vm.expectRevert(Vault.Vault__ZeroAddress.selector);
      vault.withdraw(10**18, address(0));
      vm.stopBroadcast();
   }

   function test_withdraw_succeeds() public { 
      vm.startBroadcast(USER1);
      uint256 mintAmount = 100*10**18;
      underlyingAsset.mint(USER1, mintAmount);
      underlyingAsset.approve(address(vault), mintAmount);
      vault.deposit(mintAmount);
      vm.stopBroadcast();
      vm.startBroadcast(WITHDRAW_USER);
      vault.withdraw(mintAmount, WITHDRAW_USER);
      assertEq(underlyingAsset.balanceOf(address(vault)),0);
      assertEq(underlyingAsset.balanceOf(WITHDRAW_USER),mintAmount);
      vm.stopBroadcast();
   }

   function test_trade_reverts__USER1_AccessControlUnauthorizedAccount() public {
      vm.startBroadcast(USER1);
      vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, USER1, vault.TRADER_ROLE()));
      vault.trade(address(paraswap), abi.encode("trade"));
      vm.stopBroadcast();
   }

   function test_trade_reverts_WITHDRAW_USER__AccessControlUnauthorizedAccount() public {
      vm.startBroadcast(WITHDRAW_USER);
      vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, WITHDRAW_USER, vault.TRADER_ROLE()));
      vault.trade(address(paraswap), abi.encode("trade"));
      vm.stopBroadcast();
   }

   function test_trade_reverts_ADMIN_USER__AccessControlUnauthorizedAccount() public {
      vm.startBroadcast(ADMIN_USER);
      vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, ADMIN_USER, vault.TRADER_ROLE()));
      vault.trade(address(paraswap), abi.encode("HEtradeLLO"));
      vm.stopBroadcast();
   }

   function test_trade_succeeds() public {

      uint256 fromAmount = 200 ether;
      uint256 toAmount = 150 ether;
      uint256 quoteAmount = 150 ether;

      vm.startBroadcast(TRADER_USER);
      TradeData memory tradeData = TradeData({
          srcToken: address(underlyingAsset),
          destToken: address(destToken),
          fromAmount:fromAmount,
          toAmount:toAmount,
          quotedAmount: quoteAmount,
          metadata:keccak256("metadata"),
          executor:executor,
          partnerAndFee: 3,
          permit: bytes("permit"),
          executorData: bytes("executorData")
      });
      
      bytes memory encodedTradeData = abi.encode(tradeData);
      bytes memory returnData  = vault.trade(address(paraswap), encodedTradeData);
     (uint256 recieved , uint256 partnerShare, uint256 paraswapShare) = abi.decode(returnData, (uint256,uint256, uint256 ));
      assertEq(recieved, 200);
      assertEq(partnerShare, 3);
      assertEq(paraswapShare, 5);

      vm.stopBroadcast();
    }

    function test_setAggregatorAdapter_reverts_ADMIN_USER__AccessControlUnauthorizedAccount() public {
      vm.startBroadcast(ADMIN_USER);
      vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, ADMIN_USER, DEFAULT_ADMIN_ROLE));
      vault.setAggregatorAdapter(address(paraswap), fakeAdapter );
      vm.stopBroadcast();
   }

   function test_setAggregatorAdapter_reverts_USER1__AccessControlUnauthorizedAccount() public {
      vm.startBroadcast(USER1);
      vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, USER1, DEFAULT_ADMIN_ROLE));
      vault.setAggregatorAdapter(address(paraswap), fakeAdapter );
      vm.stopBroadcast();
   }

   function test_setAggregatorAdapter_reverts_WITHDRAW_USER__AccessControlUnauthorizedAccount() public {
      vm.startBroadcast(WITHDRAW_USER);
      vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, WITHDRAW_USER, DEFAULT_ADMIN_ROLE));
      vault.setAggregatorAdapter(address(paraswap), fakeAdapter );
      vm.stopBroadcast();
   }

   function test_setAggregatorAdapter_reverts_TRADER_USER__AccessControlUnauthorizedAccount() public {
      vm.startBroadcast(TRADER_USER);
      vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, TRADER_USER, DEFAULT_ADMIN_ROLE));
      vault.setAggregatorAdapter(address(paraswap), fakeAdapter );
      vm.stopBroadcast();
   } 

   // PAUSE
   

   //  function testFuzz_SetNumber(uint256 x) public {
   //      // counter.setNumber(x);
   //      // assertEq(counter.number(), x);
   //  }
}
