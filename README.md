 # Vault Contract Documentation

## Overview

The `Vault` contract is a smart contract that allows users to deposit, withdraw, and trade ERC20 tokens. It leverages the UUPS (Universal Upgradeable Proxy Standard) pattern for upgradeability and uses roles for access control. The Vault contract uses an adapter pattern to interact with different DEX aggregators. 
The contract also supports pausing functionality to prevent certain actions when needed.

## Features

- **Deposit**: Users can deposit a specified amount of the underlying asset into the vault.
- **Withdraw**: Users with the `WITHDRAW_ROLE` can withdraw a specified amount of the underlying asset to a specified address.
- **Trade**: Users with the `TRADER_ROLE` can execute trades on specified aggregators.
- **Aggregator Adapter Pattern**: The contract uses an adapter pattern to interact with different decentralized exchange (DEX) aggregators.
- **Pause/Unpause**: The contract can be paused and unpaused by users with the `DEFAULT_ADMIN_ROLE`.

## Interfaces


### IVault

This interface defines the vault speicifcation

```solidity
interface  IVault {
    
    /// @notice Deposits a specified amount of the underlying asset into the vault
    /// @param amount The amount to deposit
    function deposit(uint256 amount) external;
    

    /// @notice Withdraws amount to specified address `to`
    /// @param amount amount to withdraw
    /// @param to address to send the amount 
    function withdraw(uint256 amount, address to) external;

    /// @notice Executes a trade on the specified aggregator
    /// @param swapper The address of the dex aggregator to execute the trade
    /// @param tradeData The data passed to the aggregator adapter
    /// @return returnData The data returned from the trade execution
    function trade(address swapper, bytes calldata tradeData) external returns(bytes calldata returnData);


    /// @notice Sets the aggregator adapter for a specified swapper
    /// @param swapper The address of the swapper
    /// @param adapter The address of the adapter
    function setAggregatorAdapter(address swapper, address adapter) external;

    /// @notice Removes the aggregator adapter for a specified swapper
    /// @param swapper The address of the swapper
    function removeAggregatorAdapter(address swapper) external;

    /// @notice Gets the aggregator adapter for a specified swapper
    /// @param swapper The address of the swapper
    /// @return The address of the adapter
    function getAggregatorAdapter(address swapper) external view returns(address);
}
```

### ISwapAdapter
This interface defines the specifcation for DEX aggregators as well as DEXes. it receives bytes data and converts it to the calldata expected by the DEX aggregator or DEX router
```solidity
interface ISwapAdapter {
    function getTradeCalldata(bytes calldata tradeData)
        external
        view
        returns (bytes memory tradeCallData, uint256 value);
}
```

### IGenericSwapExactAmountIn

This interface defines the structure for executing a swap using Paraswap's  [AugustusSwapper v6.2](https://developers.paraswap.network/augustus-swapper/augustus-v6.2). Click on this link to [find more details.](https://developers.paraswap.network/augustus-swapper/augustus-v6.2)

```solidity
interface IGenericSwapExactAmountIn {
    function swapExactAmountIn(
        address srcToken,
        address destToken,
        uint256 fromAmount,
        uint256 minToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);
}
```


### Adapter Pattern
The adpter pattern allows the Vault to use multiple dex aggregators or DEXes for trading. For every Dex aggregator that will be integrate, the IswapAdpater interface described above will be implemented and used to return the calldata required by the DEX aggregator / DEX router. The adapter for [Paraswap](https://doc.paraswap.network/) dex aggregator is located in the `adapters` directory  



### Unit Tests

The tests can be found in the tests directory of the project . to run the tests run

```
forge clean
forge test
```
