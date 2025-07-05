// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {WorldCoinsFactory} from "../src/WorldCoinsFactory.sol";

contract DeployScript is Script {
    function run() public {
        // Get deployer address (when using --private-key, msg.sender is the deployer)
        address deployer = msg.sender;
        
        console.log("Deploying WorldCoinsFactory...");
        console.log("Deployer address:", deployer);
        
        vm.startBroadcast(); // No private key needed when using --private-key parameter
        
        // Deploy WorldCoinsFactory with deployer as initial owner
        WorldCoinsFactory factory = new WorldCoinsFactory(deployer);
        
        vm.stopBroadcast();
        
        // Log deployment info
        console.log("WorldCoinsFactory deployed to:", address(factory));
        console.log("Factory owner:", factory.owner());
        console.log("Initial token count:", factory.getTokenCount());
        
        // Verify deployment
        require(factory.owner() == deployer, "Factory owner not set correctly");
        require(factory.getTokenCount() == 0, "Initial token count should be 0");
        
        console.log("Deployment successful!");
    }
} 