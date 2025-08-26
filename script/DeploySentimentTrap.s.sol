// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SentimentTrap.sol";

contract DeploySentimentTrap is Script {
    function run() external returns (address) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        SentimentTrap sentimentTrap = new SentimentTrap();

        vm.stopBroadcast();
        console.log("SentimentTrap deployed at:", address(sentimentTrap));
        return address(sentimentTrap);
    }
}
