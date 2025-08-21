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
        return abi.encode(prediction, driftThreshold);
    }

    function shouldRespond(bytes[] calldata _collectOutputs) external pure override returns (bool, bytes memory) {
        (uint256 latestPrediction, uint256 driftThreshold) = abi.decode(_collectOutputs[_collectOutputs.length - 1], (uint256, uint256));

        // Simplified drift detection: if latest prediction exceeds a direct threshold
        // The more complex, windowed analysis will be handled by the off-chain Drosera operator.
        if (latestPrediction > driftThreshold) {
            return (true, abi.encodePacked("Drift detected: Latest prediction ", Strings.toString(latestPrediction), " exceeds direct threshold ", Strings.toString(driftThreshold)));
        }

        return (false, "");
    }
}
