// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {ResponseContract} from "../src/ResponseContract.sol";

contract DeployResponseContract is Script {
    function run() external {
        vm.startBroadcast();
        ResponseContract responseContract = new ResponseContract();
        responseContract.setDroseraAddress(0x91cB447BaFc6e0EA0F4Fe056F5a9b1F14bb06e5D);
        vm.stopBroadcast();
    }
}
