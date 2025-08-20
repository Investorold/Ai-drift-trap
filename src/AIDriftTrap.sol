// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/ITrap.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./AIMock.sol";
import "./AIConfig.sol";

contract AIDriftTrap is ITrap {
    // This address is the deployed AIConfig contract on the Hoodi testnet.
    AIConfig public constant AI_CONFIG_ADDRESS = AIConfig(0x71dd5e8E61eB56A536e9073cbeAf6b9649049154);

    function collect() external view override returns (bytes memory) {
        AIMock aiModel = AIMock(AI_CONFIG_ADDRESS.aiModelAddress());
        uint256 prediction = aiModel.getPrediction();
        uint256 driftThreshold = AI_CONFIG_ADDRESS.driftThreshold();
        uint256 windowSize = AI_CONFIG_ADDRESS.windowSize();
        return abi.encode(prediction, driftThreshold, windowSize);
    }

    function shouldRespond(bytes[] calldata _collectOutputs) external pure override returns (bool, bytes memory) {
        (uint256 latestPrediction, uint256 driftThreshold, uint256 windowSize) = abi.decode(_collectOutputs[_collectOutputs.length - 1], (uint256, uint256, uint256));

        if (_collectOutputs.length < windowSize) {
            // Not enough data points for the moving average window
            return (false, "");
        }

        uint256 sum = 0;
        for (uint256 i = 0; i < windowSize; i++) {
            (uint256 prediction, ,) = abi.decode(_collectOutputs[_collectOutputs.length - 1 - i], (uint256, uint256, uint256));
            sum += prediction;
        }
        uint256 movingAverage = sum / windowSize;

        if (movingAverage == 0) {
            // Avoid division by zero, consider any change as drift if moving average was zero
            if (latestPrediction != 0) {
                return (true, abi.encodePacked("Drift detected: Moving average was zero, current is ", Strings.toString(latestPrediction)));
            }
            return (false, "");
        }

        uint256 difference = latestPrediction > movingAverage ? latestPrediction - movingAverage : movingAverage - latestPrediction;
        uint256 thresholdValue = (movingAverage * driftThreshold) / 10000; // driftThreshold is in basis points

        if (difference > thresholdValue) {
            return (true, abi.encodePacked("Drift detected: Latest prediction ", Strings.toString(latestPrediction), " deviates from moving average ", Strings.toString(movingAverage), " by more than ", Strings.toString(driftThreshold / 100), "%"));
        }

        return (false, "");
    }
}
