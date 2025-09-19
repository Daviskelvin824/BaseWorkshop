// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import "../src/BasedToken.sol";

contract BasedTokenScript is Script {
    BasedToken public token;

    function setUp() public {}

    function run() public {
        console.log("Starting BasedToken deployment to Base Testnet...");
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

        uint256 initialSupply = 1_000_000 ether; // 1M BASED with 18 decimals

        vm.startBroadcast(deployerPrivateKey);
        console.log("Deploying BasedToken contract...");
        token = new BasedToken(initialSupply);
        vm.stopBroadcast();

        console.log("BasedToken deployed at:", address(token));
        console.log("Deployer:", deployer);
    }
}
