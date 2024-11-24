// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;


/// @title Vault contract
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
