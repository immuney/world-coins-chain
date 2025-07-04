// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// WorldCoinsFactory imports
import { WorldCoinsFactory } from "../../contracts/WorldCoinsFactory.sol";

// OZ imports
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Forge imports
import "forge-std/console.sol";

// DevTools imports
import { TestHelperOz5 } from "@layerzerolabs/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";

// Mock WLD token for testing
contract MockWLDToken is ERC20 {
    constructor() ERC20("Worldcoin", "WLD") {}
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract WorldCoinsFactoryTest is TestHelperOz5 {
    uint32 private aEid = 1;

    WorldCoinsFactory private worldCoinsFactory;
    MockWLDToken private wldToken;

    address private userA = address(0x1);
    address private userB = address(0x2);
    uint256 private initialWLDBalance = 100 ether;

    function setUp() public virtual override {
        vm.deal(userA, 1000 ether);
        vm.deal(userB, 1000 ether);

        super.setUp();
        setUpEndpoints(1, LibraryType.UltraLightNode);

        // Deploy mock WLD token
        wldToken = new MockWLDToken();
        
        // Mint initial WLD tokens to users
        wldToken.mint(userA, initialWLDBalance);
        wldToken.mint(userB, initialWLDBalance);

        // Deploy WorldCoinsFactory
        worldCoinsFactory = WorldCoinsFactory(
            _deployOApp(
                type(WorldCoinsFactory).creationCode, 
                abi.encode(address(endpoints[aEid]), address(wldToken))
            )
        );
    }

    function test_constructor() public {
        assertEq(worldCoinsFactory.name(), "WorldCoins");
        assertEq(worldCoinsFactory.symbol(), "WLC");
        assertEq(address(worldCoinsFactory.WLD()), address(wldToken));
        assertEq(address(worldCoinsFactory.endpoint()), address(endpoints[aEid]));
        assertEq(worldCoinsFactory.owner(), address(this));
    }

    function test_claim_success() public {
        // Check initial state
        assertEq(worldCoinsFactory.balanceOf(userA), 0);
        assertEq(worldCoinsFactory.hasClaimed(userA), false);
        assertEq(wldToken.balanceOf(userA), initialWLDBalance);

        // Approve WLD spending and claim as userA
        vm.startPrank(userA);
        wldToken.approve(address(worldCoinsFactory), worldCoinsFactory.CLAIM_PRICE());
        worldCoinsFactory.claim();
        vm.stopPrank();

        // Check final state
        assertEq(worldCoinsFactory.balanceOf(userA), worldCoinsFactory.CLAIM_AMOUNT());
        assertEq(worldCoinsFactory.hasClaimed(userA), true);
        assertEq(wldToken.balanceOf(userA), initialWLDBalance - worldCoinsFactory.CLAIM_PRICE());
        assertEq(wldToken.balanceOf(address(worldCoinsFactory)), worldCoinsFactory.CLAIM_PRICE());
    }

    function test_claim_already_claimed() public {
        // First claim
        vm.startPrank(userA);
        wldToken.approve(address(worldCoinsFactory), worldCoinsFactory.CLAIM_PRICE());
        worldCoinsFactory.claim();
        vm.stopPrank();

        // Second claim should fail
        vm.startPrank(userA);
        wldToken.approve(address(worldCoinsFactory), worldCoinsFactory.CLAIM_PRICE());
        vm.expectRevert("Already claimed");
        worldCoinsFactory.claim();
        vm.stopPrank();
    }

    function test_claim_insufficient_wld() public {
        // Don't approve any WLD tokens
        vm.startPrank(userA);
        vm.expectRevert(); // Expect ERC20InsufficientAllowance error
        worldCoinsFactory.claim();
        vm.stopPrank();
    }

    function test_claim_insufficient_approval() public {
        // Approve less than required
        vm.startPrank(userA);
        wldToken.approve(address(worldCoinsFactory), worldCoinsFactory.CLAIM_PRICE() - 1);
        vm.expectRevert(); // Expect ERC20InsufficientAllowance error
        worldCoinsFactory.claim();
        vm.stopPrank();
    }

    function test_multiple_users_claim() public {
        // User A claims
        vm.startPrank(userA);
        wldToken.approve(address(worldCoinsFactory), worldCoinsFactory.CLAIM_PRICE());
        worldCoinsFactory.claim();
        vm.stopPrank();

        // User B claims
        vm.startPrank(userB);
        wldToken.approve(address(worldCoinsFactory), worldCoinsFactory.CLAIM_PRICE());
        worldCoinsFactory.claim();
        vm.stopPrank();

        // Check both users received tokens
        assertEq(worldCoinsFactory.balanceOf(userA), worldCoinsFactory.CLAIM_AMOUNT());
        assertEq(worldCoinsFactory.balanceOf(userB), worldCoinsFactory.CLAIM_AMOUNT());
        assertEq(worldCoinsFactory.hasClaimed(userA), true);
        assertEq(worldCoinsFactory.hasClaimed(userB), true);
        
        // Check contract received WLD from both users
        assertEq(wldToken.balanceOf(address(worldCoinsFactory)), 2 * worldCoinsFactory.CLAIM_PRICE());
    }

    function test_constants() public {
        assertEq(worldCoinsFactory.CLAIM_PRICE(), 1 ether);
        assertEq(worldCoinsFactory.CLAIM_AMOUNT(), 100 ether);
    }
} 