// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/AIDriftTrap.sol";
import "../src/AIConfig.sol"; // Import AIConfig for context
import "../src/AIMock.sol"; // Import AIMock for context

contract AIDriftTrapTest is Test {
    AIDriftTrap public aiDriftTrap;

    function setUp() public {
        // AIDriftTrap is stateless and reads config from AIConfig.
        // For testing shouldRespond, we will directly construct the _collectOutputs array.
        aiDriftTrap = new AIDriftTrap();
    }

    // Helper function to create a bytes array for a single prediction, driftThreshold, and windowSize
    function _encodeCollectOutput(uint256 prediction, uint256 driftThreshold, uint256 windowSize) internal pure returns (bytes memory) {
        return abi.encode(prediction, driftThreshold, windowSize);
    }

    // Helper function to create a _collectOutputs array for testing shouldRespond
    function _createCollectOutputs(uint256[] memory predictions, uint256 driftThreshold, uint256 windowSize) internal pure returns (bytes[] memory) {
        bytes[] memory collectOutputs = new bytes[](predictions.length);
        for (uint256 i = 0; i < predictions.length; i++) {
            collectOutputs[i] = _encodeCollectOutput(predictions[i], driftThreshold, windowSize);
        }
        return collectOutputs;
    }

    function testShouldRespond_NoDrift() public {
        uint256 driftThreshold = 100; // 1%
        uint256 windowSize = 5;
        uint256[] memory predictions = new uint256[](5);
        predictions[0] = 1000;
        predictions[1] = 1005;
        predictions[2] = 1002;
        predictions[3] = 1003;
        predictions[4] = 1001; // Latest prediction, average is around 1002.2

        bytes[] memory collectOutputs = _createCollectOutputs(predictions, driftThreshold, windowSize);

        (bool shouldRespond, bytes memory responseData) = aiDriftTrap.shouldRespond(collectOutputs);

        assertEq(shouldRespond, false, "Should not respond when there is no drift");
        assertEq(responseData.length, 0, "Response data should be empty");
    }

    function testShouldRespond_LargeDrift() public {
        uint256 driftThreshold = 100; // 1%
        uint256 windowSize = 5;
        uint256[] memory predictions = new uint256[](5);
        predictions[0] = 1000;
        predictions[1] = 1005;
        predictions[2] = 1002;
        predictions[3] = 1003;
        predictions[4] = 1200; // Latest prediction, significantly higher than average

        bytes[] memory collectOutputs = _createCollectOutputs(predictions, driftThreshold, windowSize);

        (bool shouldRespond, bytes memory responseData) = aiDriftTrap.shouldRespond(collectOutputs);

        assertEq(shouldRespond, true, "Should respond when there is large drift");
        assertGt(responseData.length, 0, "Response data should not be empty");

        // Decode and check the message content (optional, but good for detailed assertion)
        
    }

    function testShouldRespond_InsufficientData() public {
        uint256 driftThreshold = 100; // 1%
        uint256 windowSize = 5;
        uint256[] memory predictions = new uint256[](3); // Less than windowSize
        predictions[0] = 100;
        predictions[1] = 101;
        predictions[2] = 102;

        bytes[] memory collectOutputs = _createCollectOutputs(predictions, driftThreshold, windowSize);

        (bool shouldRespond, bytes memory responseData) = aiDriftTrap.shouldRespond(collectOutputs);

        assertEq(shouldRespond, false, "Should not respond when data is insufficient");
        assertEq(responseData.length, 0, "Response data should be empty");
    }

    function testShouldRespond_ZeroPredictions_NonZeroLatest() public {
        uint256 driftThreshold = 100; // 1%
        uint256 windowSize = 5;
        uint256[] memory predictions = new uint256[](5);
        predictions[0] = 0;
        predictions[1] = 0;
        predictions[2] = 0;
        predictions[3] = 0;
        predictions[4] = 100; // Latest prediction is non-zero

        bytes[] memory collectOutputs = _createCollectOutputs(predictions, driftThreshold, windowSize);

        (bool shouldRespond, bytes memory responseData) = aiDriftTrap.shouldRespond(collectOutputs);

        assertEq(shouldRespond, true, "Should respond when moving average is zero and latest is non-zero");
        assertGt(responseData.length, 0, "Response data should not be empty");

    }

    function testShouldRespond_ZeroPredictions_AllZero() public {
        uint256 driftThreshold = 100; // 1%
        uint256 windowSize = 5;
        uint256[] memory predictions = new uint256[](5);
        predictions[0] = 0;
        predictions[1] = 0;
        predictions[2] = 0;
        predictions[3] = 0;
        predictions[4] = 0; // All predictions are zero

        bytes[] memory collectOutputs = _createCollectOutputs(predictions, driftThreshold, windowSize);

        (bool shouldRespond, bytes memory responseData) = aiDriftTrap.shouldRespond(collectOutputs);

        assertEq(shouldRespond, false, "Should not respond when all predictions are zero");
        assertEq(responseData.length, 0, "Response data should be empty");
    }
}