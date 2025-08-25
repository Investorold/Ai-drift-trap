// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "../src/ChatGPTInfoStore.sol";
import "../src/ChatGPTAnalysisTrap.sol";

contract DeployChatGPTContracts is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy ChatGPTInfoStore
        ChatGPTInfoStore chatGPTInfoStore = new ChatGPTInfoStore();
        console.log("ChatGPTInfoStore deployed to:", address(chatGPTInfoStore));

        // Deploy ChatGPTAnalysisTrap
        ChatGPTAnalysisTrap chatGPTAnalysisTrap = new ChatGPTAnalysisTrap();
        console.log("ChatGPTAnalysisTrap deployed to:", address(chatGPTAnalysisTrap));

        vm.stopBroadcast();
    }
}
