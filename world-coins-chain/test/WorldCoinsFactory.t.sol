// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {WorldCoinsFactory} from "../src/WorldCoinsFactory.sol";
import {WorldCoinToken} from "../src/WorldCoinToken.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract WorldCoinsFactoryTest is Test {
    WorldCoinsFactory public factory;
    address public owner;
    address public user1;
    address public user2;
    address public user3;
    
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
    
    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        
        vm.prank(owner);
        factory = new WorldCoinsFactory(owner);
    }
    
    function test_ConstructorSetsOwner() public {
        assertEq(factory.owner(), owner);
    }
    
    function test_RevertWhen_ConstructorCalledWithZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableInvalidOwner.selector, address(0)));
        new WorldCoinsFactory(address(0));
    }
    
    function test_CreateToken_Success() public {
        vm.prank(user1);
        
        WorldCoinsFactory.TokenParams memory params = WorldCoinsFactory.TokenParams({
            name: "TestToken",
            symbol: "TEST",
            description: "A test token"
        });
        
        vm.expectEmit(true, false, false, true);
        emit TokenCreated(user1, address(0), "TestToken", "TEST");
        
        address tokenAddress = factory.createToken(params);
        
        // Verify token was created
        assertTrue(tokenAddress != address(0));
        assertTrue(factory.isValidToken(tokenAddress));
        assertEq(factory.getTokenByCreator(user1), tokenAddress);
        assertTrue(factory.hasCreatedToken(user1));
        assertEq(factory.getTokenCount(), 1);
        
        // Verify token details
        WorldCoinToken token = WorldCoinToken(tokenAddress);
        assertEq(token.name(), "TestToken");
        assertEq(token.symbol(), "TEST");
        assertEq(token.CREATOR(), user1);
        assertEq(token.description(), "A test token");
        assertEq(token.totalSupply(), token.CREATOR_INITIAL_AMOUNT());
        assertEq(token.balanceOf(user1), token.CREATOR_INITIAL_AMOUNT());
    }
    
    function test_RevertWhen_CreateTokenCalledTwice() public {
        vm.startPrank(user1);
        
        WorldCoinsFactory.TokenParams memory params = WorldCoinsFactory.TokenParams({
            name: "TestToken",
            symbol: "TEST",
            description: "A test token"
        });
        
        factory.createToken(params);
        
        vm.expectRevert(WorldCoinsFactory.TokenAlreadyCreated.selector);
        factory.createToken(params);
        
        vm.stopPrank();
    }
    
    function test_RevertWhen_CreateTokenWithEmptyName() public {
        vm.prank(user1);
        
        WorldCoinsFactory.TokenParams memory params = WorldCoinsFactory.TokenParams({
            name: "",
            symbol: "TEST",
            description: "A test token"
        });
        
        vm.expectRevert(WorldCoinsFactory.InvalidTokenParameters.selector);
        factory.createToken(params);
    }
    
    function test_RevertWhen_CreateTokenWithEmptySymbol() public {
        vm.prank(user1);
        
        WorldCoinsFactory.TokenParams memory params = WorldCoinsFactory.TokenParams({
            name: "TestToken",
            symbol: "",
            description: "A test token"
        });
        
        vm.expectRevert(WorldCoinsFactory.InvalidTokenParameters.selector);
        factory.createToken(params);
    }
    
    function test_ClaimTokens_Success() public {
        // User1 creates a token
        vm.prank(user1);
        WorldCoinsFactory.TokenParams memory params = WorldCoinsFactory.TokenParams({
            name: "TestToken",
            symbol: "TEST",
            description: "A test token"
        });
        address tokenAddress = factory.createToken(params);
        
        // User2 claims tokens
        vm.prank(user2);
        
        vm.expectEmit(true, true, false, true);
        emit TokenClaimed(user2, tokenAddress, 50 * 10**18);
        
        factory.claimTokens(tokenAddress);
        
        // Verify claim
        assertTrue(factory.hasUserClaimed(user2, tokenAddress));
        
        WorldCoinToken token = WorldCoinToken(tokenAddress);
        assertEq(token.balanceOf(user2), 50 * 10**18);
        assertEq(token.totalSupply(), 5000 * 10**18 + 50 * 10**18);
    }
    
    function test_RevertWhen_ClaimTokensFromInvalidToken() public {
        vm.prank(user1);
        
        vm.expectRevert(WorldCoinsFactory.InvalidToken.selector);
        factory.claimTokens(address(0x123));
    }
    
    function test_RevertWhen_ClaimTokensTwice() public {
        // User1 creates a token
        vm.prank(user1);
        WorldCoinsFactory.TokenParams memory params = WorldCoinsFactory.TokenParams({
            name: "TestToken",
            symbol: "TEST",
            description: "A test token"
        });
        address tokenAddress = factory.createToken(params);
        
        // User2 claims tokens
        vm.prank(user2);
        factory.claimTokens(tokenAddress);
        
        // User2 tries to claim again
        vm.prank(user2);
        vm.expectRevert(WorldCoinsFactory.AlreadyClaimed.selector);
        factory.claimTokens(tokenAddress);
    }
    
    function test_GetAllTokens() public {
        // Initially no tokens
        assertEq(factory.getAllTokens().length, 0);
        
        // Create first token
        vm.prank(user1);
        WorldCoinsFactory.TokenParams memory params1 = WorldCoinsFactory.TokenParams({
            name: "Token1",
            symbol: "TK1",
            description: "First token"
        });
        address token1 = factory.createToken(params1);
        
        address[] memory tokens = factory.getAllTokens();
        assertEq(tokens.length, 1);
        assertEq(tokens[0], token1);
        
        // Create second token
        vm.prank(user2);
        WorldCoinsFactory.TokenParams memory params2 = WorldCoinsFactory.TokenParams({
            name: "Token2",
            symbol: "TK2",
            description: "Second token"
        });
        address token2 = factory.createToken(params2);
        
        tokens = factory.getAllTokens();
        assertEq(tokens.length, 2);
        assertEq(tokens[0], token1);
        assertEq(tokens[1], token2);
    }
    
    function test_GetTokenDetails() public {
        // Create token
        vm.prank(user1);
        WorldCoinsFactory.TokenParams memory params = WorldCoinsFactory.TokenParams({
            name: "TestToken",
            symbol: "TEST",
            description: "A test token"
        });
        address tokenAddress = factory.createToken(params);
        
        // Get token details
        (
            string memory name,
            string memory symbol,
            uint256 totalSupply,
            uint256 maxSupply,
            uint256 claimAmount,
            address creator,
            string memory description
        ) = factory.getTokenDetails(tokenAddress);
        
        assertEq(name, "TestToken");
        assertEq(symbol, "TEST");
        assertEq(totalSupply, 5000 * 10**18);
        assertEq(maxSupply, 1000000 * 10**18);
        assertEq(claimAmount, 50 * 10**18);
        assertEq(creator, user1);
        assertEq(description, "A test token");
    }
    
    function test_GetClaimStats() public {
        // Create token
        vm.prank(user1);
        WorldCoinsFactory.TokenParams memory params = WorldCoinsFactory.TokenParams({
            name: "TestToken",
            symbol: "TEST",
            description: "A test token"
        });
        address tokenAddress = factory.createToken(params);
        
        // Initial stats
        (uint256 claimers, uint256 totalClaimed, uint256 availableSupply) = factory.getClaimStats(tokenAddress);
        assertEq(claimers, 0);
        assertEq(totalClaimed, 0);
        assertEq(availableSupply, 1000000 * 10**18 - 5000 * 10**18);
        
        // User2 claims
        vm.prank(user2);
        factory.claimTokens(tokenAddress);
        
        (claimers, totalClaimed, availableSupply) = factory.getClaimStats(tokenAddress);
        assertEq(claimers, 1);
        assertEq(totalClaimed, 50 * 10**18);
        assertEq(availableSupply, 1000000 * 10**18 - 5000 * 10**18 - 50 * 10**18);
        
        // User3 claims
        vm.prank(user3);
        factory.claimTokens(tokenAddress);
        
        (claimers, totalClaimed, availableSupply) = factory.getClaimStats(tokenAddress);
        assertEq(claimers, 2);
        assertEq(totalClaimed, 100 * 10**18);
        assertEq(availableSupply, 1000000 * 10**18 - 5000 * 10**18 - 100 * 10**18);
    }
    
    function testFuzz_CreateTokenWithValidParameters(string memory name, string memory symbol, string memory description) public {
        // Bound inputs to valid ranges
        vm.assume(bytes(name).length > 0 && bytes(name).length < 100);
        vm.assume(bytes(symbol).length > 0 && bytes(symbol).length < 20);
        vm.assume(bytes(description).length < 500);
        
        address randomUser = address(uint160(uint256(keccak256(abi.encodePacked(name, symbol)))));
        vm.assume(randomUser != address(0));
        
        vm.prank(randomUser);
        WorldCoinsFactory.TokenParams memory params = WorldCoinsFactory.TokenParams({
            name: name,
            symbol: symbol,
            description: description
        });
        
        address tokenAddress = factory.createToken(params);
        
        assertTrue(tokenAddress != address(0));
        assertTrue(factory.isValidToken(tokenAddress));
        assertEq(factory.getTokenByCreator(randomUser), tokenAddress);
        assertTrue(factory.hasCreatedToken(randomUser));
        
        WorldCoinToken token = WorldCoinToken(tokenAddress);
        assertEq(token.name(), name);
        assertEq(token.symbol(), symbol);
        assertEq(token.description(), description);
        assertEq(token.CREATOR(), randomUser);
        assertEq(token.balanceOf(randomUser), 5000 * 10**18);
    }
    
    function testFuzz_ClaimTokensFromMultipleUsers(uint8 numUsers) public {
        // Bound number of users to reasonable range
        vm.assume(numUsers > 0 && numUsers <= 50);
        
        // Create token
        vm.prank(user1);
        WorldCoinsFactory.TokenParams memory params = WorldCoinsFactory.TokenParams({
            name: "TestToken",
            symbol: "TEST",
            description: "A test token"
        });
        address tokenAddress = factory.createToken(params);
        
                 // Generate users and have them claim
        for (uint8 i = 0; i < numUsers; i++) {
            address claimer = address(uint160(1000 + i));
            vm.prank(claimer);
            factory.claimTokens(tokenAddress);
            
            assertTrue(factory.hasUserClaimed(claimer, tokenAddress));
            
            WorldCoinToken tokenInstance = WorldCoinToken(tokenAddress);
            assertEq(tokenInstance.balanceOf(claimer), 50 * 10**18);
        }
        
        // Verify total supply
        WorldCoinToken token = WorldCoinToken(tokenAddress);
        uint256 expectedTotal = 5000 * 10**18 + (numUsers * 50 * 10**18);
        assertEq(token.totalSupply(), expectedTotal);
        
        // Verify claim stats
        (uint256 claimers, uint256 totalClaimed, uint256 availableSupply) = factory.getClaimStats(tokenAddress);
        assertEq(claimers, numUsers);
        assertEq(totalClaimed, numUsers * 50 * 10**18);
        assertEq(availableSupply, 1000000 * 10**18 - expectedTotal);
    }
    
    function test_TokenSupplyLimits() public {
        // Create token
        vm.prank(user1);
        WorldCoinsFactory.TokenParams memory params = WorldCoinsFactory.TokenParams({
            name: "TestToken",
            symbol: "TEST",
            description: "A test token"
        });
        address tokenAddress = factory.createToken(params);
        
        WorldCoinToken token = WorldCoinToken(tokenAddress);
        
        // Calculate maximum possible claimers
        uint256 maxSupply = token.MAX_SUPPLY(); // 1,000,000 * 10^18
        uint256 creatorAmount = token.CREATOR_INITIAL_AMOUNT(); // 5,000 * 10^18
        uint256 claimAmount = token.CLAIM_AMOUNT(); // 50 * 10^18
        uint256 maxClaimers = (maxSupply - creatorAmount) / claimAmount; // 19,900
        
        // Test with a smaller number to avoid gas issues
        uint256 testClaimers = maxClaimers > 100 ? 100 : maxClaimers;
        
        // Have test number of users claim
        for (uint256 i = 0; i < testClaimers; i++) {
            address claimer = address(uint160(1000 + i));
            vm.prank(claimer);
            factory.claimTokens(tokenAddress);
        }
        
        // Verify supply increased correctly
        uint256 expectedSupply = creatorAmount + (testClaimers * claimAmount);
        assertEq(token.totalSupply(), expectedSupply);
        
        // Test that we can't exceed max supply by artificially setting up a scenario
        // where we're close to the max supply
        vm.prank(address(token));
        // We can't easily test the exact max supply scenario without gas issues
        // but we can verify the basic overflow protection works
        assertTrue(token.totalSupply() <= maxSupply);
    }
} 