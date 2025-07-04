// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { WorldCoinsFactory } from "../contracts/WorldCoinsFactory.sol";

contract ClaimWLC is Script {
    function run() external {
        // Get parameters from environment variables
        address worldCoinsFactoryAddress = vm.envAddress("WORLD_COINS_FACTORY_ADDRESS");
        uint256 signerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        address signer = vm.addr(signerPrivateKey);
        
        console.log("Starting WLC claim process...");
        console.log("WorldCoinsFactory address:", worldCoinsFactoryAddress);
        console.log("Signer address:", signer);
        
        WorldCoinsFactory worldCoinsFactory = WorldCoinsFactory(worldCoinsFactoryAddress);
        
        // Check if user has already claimed
        bool hasClaimed = worldCoinsFactory.hasClaimed(signer);
        if (hasClaimed) {
            console.log("ERROR: Address has already claimed WLC tokens");
            return;
        }
        
        // Get WLD token contract
        IERC20 wldTokenContract = worldCoinsFactory.WLD();
        
        // Get claim constants
        uint256 claimPrice = worldCoinsFactory.CLAIM_PRICE();
        uint256 claimAmount = worldCoinsFactory.CLAIM_AMOUNT();
        
        console.log("Claim price:", claimPrice);
        console.log("Claim amount:", claimAmount);
        
        // Check WLD balance
        uint256 wldBalance = wldTokenContract.balanceOf(signer);
        console.log("WLD balance:", wldBalance);
        
        if (wldBalance < claimPrice) {
            console.log("ERROR: Insufficient WLD balance");
            console.log("Required:", claimPrice);
            console.log("Available:", wldBalance);
            return;
        }
        
        vm.startBroadcast(signerPrivateKey);
        
        // 1. Approve WLD spending
        console.log("Approving WLD spending...");
        wldTokenContract.approve(worldCoinsFactoryAddress, claimPrice);
        
        // 2. Claim WLC tokens
        console.log("Claiming WLC tokens...");
        worldCoinsFactory.claim();
        
        vm.stopBroadcast();
        
        // Check final balances
        uint256 finalWLCBalance = worldCoinsFactory.balanceOf(signer);
        uint256 finalWLDBalance = wldTokenContract.balanceOf(signer);
        
        console.log("Final WLC balance:", finalWLCBalance);
        console.log("Final WLD balance:", finalWLDBalance);
        console.log("Successfully claimed WLC tokens!");
    }
} 