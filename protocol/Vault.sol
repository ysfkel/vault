// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import  "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import  "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IGenericSwapExactAmountIn.sol";
import "./interfaces/ISwapAdapter.sol";
import "./interfaces/IVault.sol";

/// @title Vault contract
contract  Vault is IVault, Initializable, UUPSUpgradeable, AccessControlUpgradeable , ReentrancyGuardUpgradeable,PausableUpgradeable, ERC20Upgradeable{
   using Address for address;

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

    error Vault__ZeroAddress();
    error Vault__ZeroAmount();
    error Vault__UnsupportedSwapper(address); 

    event Trade(address sender, address aggregator);
    event Deposit(address account, uint256 amount);
    event Withdraw(address sender,address to, uint256 amount);

    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
    bytes32 public constant TRADER_ROLE = keccak256("TRADER_ROLE");

    mapping(address swapper => address adapter) swapAdapter;
    IERC20 public asset;

    /// @notice Initializes the Vault contract
    /// @param _name The name of the ERC20 token
    /// @param _symbol The symbol of the ERC20 token
    /// @param _asset The address of the underlying asset
    /// @param _swapper The address of the swapper
    /// @param _adapter The address of the adapter
    function initialize(string memory _name, string memory _symbol,address _asset, address _swapper, address _adapter ) external initializer {
        if(_asset == address(0)) revert Vault__ZeroAddress();
        __ERC20_init(_name, _symbol);
        __UUPSUpgradeable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        __Pausable_init();  
        asset = IERC20(_asset);
        swapAdapter[_swapper] = _adapter;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    
    /// @inheritdoc IVault
    function deposit(uint256 amount) external whenNotPaused {
        if(amount == 0) revert Vault__ZeroAmount();
        asset.transferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount);
    }
    

     /// @inheritdoc IVault
    function withdraw(uint256 amount, address to) external nonReentrant whenNotPaused onlyRole(WITHDRAW_ROLE)  {
        if(amount == 0) revert Vault__ZeroAmount();
        if(to == address(0)) revert Vault__ZeroAddress();

        asset.transfer(to, amount);
        emit Withdraw(msg.sender, to, amount);
    }

    /// @inheritdoc IVault
    function trade(address swapper, bytes memory tradeData) public nonReentrant whenNotPaused onlyRole(TRADER_ROLE) returns(bytes memory returnData)  {
        // get dex aggregator adapter address
        address _aggregatorAdapterAddress = swapAdapter[swapper];
        if(_aggregatorAdapterAddress == address(0)) revert Vault__UnsupportedSwapper(swapper);
 
        ISwapAdapter adapter = ISwapAdapter(_aggregatorAdapterAddress);
         
        // get dex aggregator calldata from adapter
        (bytes memory tradeCallData, uint256 value) = adapter.getTradeCalldata(tradeData);
        // functionCallWithValue handles revert if call fails
        returnData =  swapper.functionCallWithValue(tradeCallData, value); 

        emit Trade(msg.sender, swapper);
    }


    /// @inheritdoc IVault
    function setAggregatorAdapter(address swapper, address adapter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        swapAdapter[swapper] = adapter;
    }

    /// @inheritdoc IVault
    function removeAggregatorAdapter(address swapper) external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete swapAdapter[swapper];
    }
 

    /// @inheritdoc IVault
    function getAggregatorAdapter(address swapper) external view returns(address) {
        return swapAdapter[swapper];
    }

    /// @notice Pauses the contract, preventing certain actions
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause(); 
    }

    /// @notice Unpauses the contract, allowing certain actions
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
         _unpause();
    }

    /// @notice Authorizes an upgrade to a new implementation
    /// @param newImplementation The address of the new implementation
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
