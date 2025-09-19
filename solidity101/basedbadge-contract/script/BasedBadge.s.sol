// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import "../src/BasedBadge.sol";

contract BasedBadgeScript is Script {
    BasedBadge public badge;

    function setUp() public {}

    function run() public {
        console.log("Starting BasedBadge deployment to Base Testnet...");
        console.log("");

        // Load deployer's private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deployment Details:");
        console.log("Deployer address:", deployer);

        // Check balance
        uint256 balance = deployer.balance;
        console.log("Deployer balance:", balance / 1e18, "ETH");

        if (balance < 0.01 ether) {
            console.log("Warning: Low balance. Make sure you have enough ETH for deployment.");
        }

        // Get network info
        console.log("Network: Base Testnet");
        console.log("Chain ID: 84532");
        console.log("RPC URL: https://sepolia.base.org");
        console.log("");

        vm.startBroadcast(deployerPrivateKey);
        console.log("Deploying BasedBadge contract...");
        badge = new BasedBadge();
        vm.stopBroadcast();

        console.log("BasedBadge deployed at:", address(badge));
        console.log("Deployer:", deployer);
        
        // Verify roles are properly set
        console.log("");
        console.log("Role Verification:");
        console.log("Admin role granted:", badge.hasRole(badge.DEFAULT_ADMIN_ROLE(), deployer));
        console.log("Minter role granted:", badge.hasRole(badge.MINTER_ROLE(), deployer));
        console.log("Pauser role granted:", badge.hasRole(badge.PAUSER_ROLE(), deployer));
        console.log("URI Setter role granted:", badge.hasRole(badge.URI_SETTER_ROLE(), deployer));
        
        console.log("");
        console.log("Deployment completed successfully!");
    }
}


