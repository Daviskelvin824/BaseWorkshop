// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {BasedCertificate} from "../src/BasedCertificate.sol";

contract BasedCertificateScript is Script {
    BasedCertificate public cert;

    function setUp() public {}

    function run() public {
        // Start broadcasting transactions (deployment) with your private key
        vm.startBroadcast();

        // Deploy the BasedCertificate contract
        cert = new BasedCertificate();

        // Optional: log the deployed contract address
        console.log("BasedCertificate deployed at:", address(cert));

        vm.stopBroadcast();
    }
}
