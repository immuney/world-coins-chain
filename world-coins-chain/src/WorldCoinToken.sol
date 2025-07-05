// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title WorldCoinToken
/// @notice Base ERC20 token that can be created by the WorldCoinsFactory
/// @dev This contract is deployed by the factory and has a fixed supply with claim functionality
contract WorldCoinToken is ERC20, Ownable {
    /// @notice The factory contract that created this token
    address public immutable FACTORY;
    
    /// @notice The maximum supply of this token (fixed at 1,000,000)
    uint256 public constant MAX_SUPPLY = 1_000_000 * 10**18;
    
    /// @notice The amount of tokens given per claim (fixed at 50)
    uint256 public constant CLAIM_AMOUNT = 50 * 10**18;
    
    /// @notice Initial amount given to creator (fixed at 5,000)
    uint256 public constant CREATOR_INITIAL_AMOUNT = 5_000 * 10**18;
    
    /// @notice Token creator's address
    address public immutable CREATOR;
    
    /// @notice Token metadata
    string public description;
    
    /// @notice Events
    event TokensClaimed(address indexed claimer, uint256 amount);
    
    /// @notice Errors
    error OnlyFactory();
    error MaxSupplyExceeded();
    error InsufficientSupply();
    
    /// @notice Modifier to ensure only factory can call certain functions
    modifier onlyFactory() {
        if (msg.sender != FACTORY) revert OnlyFactory();
        _;
    }
    
    /// @notice Constructor - only called by the factory
    /// @param name_ Token name
    /// @param symbol_ Token symbol
    /// @param creator_ Address of the token creator
    /// @param description_ Token description
    constructor(
        string memory name_,
        string memory symbol_,
        address creator_,
        string memory description_
    ) ERC20(name_, symbol_) Ownable(creator_) {
        FACTORY = msg.sender;
        CREATOR = creator_;
        description = description_;
        
        // Mint initial supply to creator (5,000 tokens)
        _mint(creator_, CREATOR_INITIAL_AMOUNT);
    }
    
    /// @notice Mint tokens to a claimer (only callable by factory)
    /// @param to Address to mint tokens to
    /// @param amount Amount of tokens to mint
    function mint(address to, uint256 amount) external onlyFactory {
        if (totalSupply() + amount > MAX_SUPPLY) revert MaxSupplyExceeded();
        _mint(to, amount);
        emit TokensClaimed(to, amount);
    }
    
    /// @notice Get token information
    /// @return name_ Token name
    /// @return symbol_ Token symbol
    /// @return totalSupply_ Current total supply
    /// @return maxSupply_ Maximum supply
    /// @return claimAmount_ Amount per claim
    /// @return creator_ Token creator address
    /// @return description_ Token description
    function getTokenInfo() external view returns (
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint256 maxSupply_,
        uint256 claimAmount_,
        address creator_,
        string memory description_
    ) {
        return (
            name(),
            symbol(),
            totalSupply(),
            MAX_SUPPLY,
            CLAIM_AMOUNT,
            CREATOR,
            description
        );
    }
    
    /// @notice Update token description (only creator)
    /// @param newDescription New description
    function updateDescription(string memory newDescription) external onlyOwner {
        description = newDescription;
    }
} 