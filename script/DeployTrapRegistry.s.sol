// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/TrapRegistry.sol";

contract DeployTrapRegistry is Script {
    function run() external returns (TrapRegistry) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        TrapRegistry trapRegistry = new TrapRegistry();
        console.log("TrapRegistry deployed to:", address(trapRegistry));

        vm.stopBroadcast();

        return trapRegistry;
    }
}
