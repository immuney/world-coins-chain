// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {WorldCoinsFactory} from "../src/WorldCoinsFactory.sol";

contract DeployLocalScript is Script {
    function run() public {
        // Use a test address for local deployment
        address testOwner = address(0x1234567890123456789012345678901234567890);
        
        console.log("Deploying WorldCoinsFactory locally...");
        console.log("Test owner address:", testOwner);
        
        // Deploy WorldCoinsFactory with test owner
        WorldCoinsFactory factory = new WorldCoinsFactory(testOwner);
        
        // Log deployment info
        console.log("WorldCoinsFactory deployed to:", address(factory));
        console.log("Factory owner:", factory.owner());
        console.log("Initial token count:", factory.getTokenCount());
        
        // Verify deployment
        require(factory.owner() == testOwner, "Factory owner not set correctly");
        require(factory.getTokenCount() == 0, "Initial token count should be 0");
        
        console.log("Local deployment successful!");
    }
} 