// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { WorldCoinsFactory } from "../contracts/WorldCoinsFactory.sol";

contract DeployWorldCoinsFactory is Script {
    function run() external {
        // Get deployment parameters from environment variables
        address endpointV2 = vm.envAddress("ENDPOINT_V2");
        address wldToken = vm.envAddress("WLD_TOKEN_ADDRESS");
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Log deployment info
        console.log("Deploying WorldCoinsFactory...");
        console.log("Endpoint V2:", endpointV2);
        console.log("WLD Token:", wldToken);
        console.log("Deployer:", vm.addr(deployerPrivateKey));

        vm.startBroadcast(deployerPrivateKey);

        WorldCoinsFactory worldCoinsFactory = new WorldCoinsFactory(endpointV2, wldToken);

        vm.stopBroadcast();

        console.log("WorldCoinsFactory deployed to:", address(worldCoinsFactory));
    }
} 