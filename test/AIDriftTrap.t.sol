// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/AIDriftTrap.sol";
import "../src/AIMock.sol";

contract AIDriftTrapTest is Test {
    // AIMock public aiMock;
    // AIDriftTrap public aiDriftTrap;

    // function setUp() public {
    //     aiMock = new AIMock();
    //     aiDriftTrap = new AIDriftTrap(address(aiMock), 100, 5); // 1% drift threshold, window size of 5
    // }

    // function testCollectFunction() public {
    //     bytes memory collectedData = aiDriftTrap.collect();
    //     // Assert that some data is returned
    //     assertGt(collectedData.length, 0);

    //     // Decode and check the prediction (optional, but good for sanity check)
    //     uint256 prediction = abi.decode(collectedData, (uint256));
    //     assertEq(prediction, 123); // Based on AIMock's dummy prediction
    // }

    // function testShouldRespondFunction() public {
    //     bytes[] memory emptyCollectOutputs;
    //     (bool shouldRespond, bytes memory responseData) = aiDriftTrap.shouldRespond(emptyCollectOutputs);
    //     assertEq(shouldRespond, false);
    //     assertEq(responseData, "");
    // }
}
