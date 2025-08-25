// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/TrapRegistry.sol";

contract RegisterChatGPTAnalysisTrap is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Address of the newly deployed TrapRegistry
        TrapRegistry trapRegistry = TrapRegistry(0x1BD6B2e8785a272d688A8dFd812d3b5FE338c8F9);

        // Address of the deployed ChatGPTAnalysisTrap
        address chatGPTAnalysisTrapAddress = 0xa806f458d9308A32b90CE8fb57539A4733B30ea7;

        // Register the ChatGPTAnalysisTrap
        trapRegistry.setAddress("ChatGPTAnalysisTrap", chatGPTAnalysisTrapAddress);
        console.log("ChatGPTAnalysisTrap registered with TrapRegistry.");

        vm.stopBroadcast();
    }
}
