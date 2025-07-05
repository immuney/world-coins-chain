// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { WorldCoinsFactory } from "../contracts/WorldCoinsFactory.sol";

contract DeployWorldCoinsFactory is Script {
    function run() external {
        // Get deployer address (when using --private-key, msg.sender is the deployer)
        address deployer = msg.sender;
        
        console.log("Deploying WorldCoinsFactory...");
        console.log("Deployer address:", deployer);
        
        vm.startBroadcast(); // No private key needed when using --private-key parameter
        
        // Deploy WorldCoinsFactory with deployer as initial owner
        WorldCoinsFactory worldCoinsFactory = new WorldCoinsFactory(deployer);
        
        vm.stopBroadcast();
        
        // Log deployment info
        console.log("WorldCoinsFactory deployed to:", address(worldCoinsFactory));
        console.log("Factory owner:", worldCoinsFactory.owner());
        console.log("Initial token count:", worldCoinsFactory.getTokenCount());
        
        // Verify deployment
        require(worldCoinsFactory.owner() == deployer, "Factory owner not set correctly");
        require(worldCoinsFactory.getTokenCount() == 0, "Initial token count should be 0");
        
        console.log("Deployment successful!");
    }
} 