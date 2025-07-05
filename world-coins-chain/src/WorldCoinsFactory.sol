// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {WorldCoinToken} from "./WorldCoinToken.sol";

/// @title WorldCoinsFactory
/// @notice Factory contract for creating and managing WorldCoin tokens
/// @dev Handles token creation, user verification, and claims management
contract WorldCoinsFactory is Ownable, ReentrancyGuard {
    
    /// @notice Array of all created tokens
    address[] public allTokens;
    
    /// @notice Mapping from creator address to their created token address
    mapping(address => address) public creatorToToken;
    
    /// @notice Mapping from token address to whether it was created by this factory
    mapping(address => bool) public isValidToken;
    
    /// @notice Mapping from user address to mapping of token address to whether they claimed
    mapping(address => mapping(address => bool)) public hasClaimed;
    
    /// @notice Mapping from user address to whether they have created a token
    mapping(address => bool) public hasCreatedToken;
    
    /// @notice Events
    event TokenCreated(
        address indexed creator,
        address indexed tokenAddress,
        string name,
        string symbol
    );
    
    event TokenClaimed(
        address indexed claimer,
        address indexed tokenAddress,
        uint256 amount
    );
    
    /// @notice Errors
    error TokenAlreadyCreated();
    error InvalidTokenParameters();
    error TokenNotFound();
    error AlreadyClaimed();
    error InsufficientSupply();
    error InvalidToken();
    
    /// @notice Struct to hold token creation parameters
    struct TokenParams {
        string name;
        string symbol;
        string description;
    }
    
    /// @notice Constructor
    /// @param initialOwner Address of the initial owner
    constructor(
        address initialOwner
    ) Ownable(initialOwner) {
        // OpenZeppelin's Ownable constructor handles zero address check
    }
    
    /// @notice Create a new token (only one per user)
    /// @param params Token creation parameters
    /// @return tokenAddress Address of the created token
    function createToken(TokenParams calldata params) 
        external 
        nonReentrant 
        returns (address tokenAddress) 
    {
        if (hasCreatedToken[msg.sender]) revert TokenAlreadyCreated();
        
        // Validate parameters
        if (bytes(params.name).length == 0) revert InvalidTokenParameters();
        if (bytes(params.symbol).length == 0) revert InvalidTokenParameters();
        
        // Create new token
        WorldCoinToken newToken = new WorldCoinToken(
            params.name,
            params.symbol,
            msg.sender,
            params.description
        );
        
        tokenAddress = address(newToken);
        
        // Update mappings
        allTokens.push(tokenAddress);
        creatorToToken[msg.sender] = tokenAddress;
        isValidToken[tokenAddress] = true;
        hasCreatedToken[msg.sender] = true;
        
        emit TokenCreated(
            msg.sender,
            tokenAddress,
            params.name,
            params.symbol
        );
    }
    
    /// @notice Claim tokens from a specific token contract
    /// @param tokenAddress Address of the token to claim from
    function claimTokens(address tokenAddress) external nonReentrant {
        if (!isValidToken[tokenAddress]) revert InvalidToken();
        if (hasClaimed[msg.sender][tokenAddress]) revert AlreadyClaimed();
        
        WorldCoinToken token = WorldCoinToken(tokenAddress);
        
        // Mark as claimed
        hasClaimed[msg.sender][tokenAddress] = true;
        
        // Mint tokens to user (50 tokens)
        token.mint(msg.sender, token.CLAIM_AMOUNT());
        
        emit TokenClaimed(msg.sender, tokenAddress, token.CLAIM_AMOUNT());
    }
    
    /// @notice Get all created tokens
    /// @return Array of all token addresses
    function getAllTokens() external view returns (address[] memory) {
        return allTokens;
    }
    
    /// @notice Get the number of created tokens
    /// @return Number of tokens created
    function getTokenCount() external view returns (uint256) {
        return allTokens.length;
    }
    
    /// @notice Get token address created by a specific user
    /// @param creator Address of the creator
    /// @return Token address (zero address if none)
    function getTokenByCreator(address creator) external view returns (address) {
        return creatorToToken[creator];
    }
    
    /// @notice Check if a user has claimed from a specific token
    /// @param user Address of the user
    /// @param tokenAddress Address of the token
    /// @return Whether the user has claimed
    function hasUserClaimed(address user, address tokenAddress) external view returns (bool) {
        return hasClaimed[user][tokenAddress];
    }
    
    /// @notice Get detailed information about a token
    /// @param tokenAddress Address of the token
    /// @return name Token name
    /// @return symbol Token symbol
    /// @return totalSupply Current total supply
    /// @return maxSupply Maximum supply
    /// @return claimAmount Amount per claim
    /// @return creator Token creator address
    /// @return description Token description
    function getTokenDetails(address tokenAddress) external view returns (
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint256 maxSupply,
        uint256 claimAmount,
        address creator,
        string memory description
    ) {
        if (!isValidToken[tokenAddress]) revert InvalidToken();
        WorldCoinToken token = WorldCoinToken(tokenAddress);
        return token.getTokenInfo();
    }
    
    /// @notice Get claim statistics for a token
    /// @param tokenAddress Address of the token
    /// @return claimers Number of unique claimers
    /// @return totalClaimed Total amount claimed
    /// @return availableSupply Remaining supply for claims
    function getClaimStats(address tokenAddress) external view returns (
        uint256 claimers,
        uint256 totalClaimed,
        uint256 availableSupply
    ) {
        if (!isValidToken[tokenAddress]) revert InvalidToken();
        WorldCoinToken token = WorldCoinToken(tokenAddress);
        
        uint256 totalSupply = token.totalSupply();
        uint256 maxSupply = token.MAX_SUPPLY();
        uint256 claimAmount = token.CLAIM_AMOUNT();
        
        // Calculate based on total supply and initial creator mint (5,000 tokens)
        uint256 initialCreatorMint = token.CREATOR_INITIAL_AMOUNT();
        totalClaimed = totalSupply > initialCreatorMint ? totalSupply - initialCreatorMint : 0;
        claimers = totalClaimed / claimAmount;
        availableSupply = maxSupply - totalSupply;
    }
    

} 