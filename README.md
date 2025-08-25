# My AI Parameter Drift Detection Trap Project

This repository documents my journey in building and deploying a custom AI parameter drift detection trap on the Drosera network. This trap is designed to continuously monitor the predictions of an on-chain AI model. When a significant deviation (drift) from its expected behavior is detected, the trap automatically triggers a predefined on-chain response. The project highlights the key architectural decisions, such as a stateless trap design and external configuration, and the solutions to significant challenges encountered during development and deployment.

## Table of Contents

1.  [Project Overview](#1-project-overview)
2.  [Understanding AI Model Drift and its Implications](#2-understanding-ai-model-drift-and-its-implications)
3.  [Core Project Components](#3-core-project-components)
4.  [Key Challenges & Solutions](#4-key-challenges--solutions)
5.  [Deployment Workflow](#5-deployment-workflow)
6.  [Operator Setup](#6-operator-setup)
7.  [End-to-End Test & Verification](#7-end-to-end-test--verification)
8.  [Comprehensive Testing of `shouldRespond`](#8-comprehensive-testing-of-shouldrespond)
9.  [Conclusion](#9-conclusion)

---

## 1. Project Overview

My goal was to create a Drosera trap that monitors an on-chain AI model's predictions for significant "drift" and triggers an on-chain response when detected. This project involved developing custom Solidity contracts, configuring Drosera's `drosera.toml`, and setting up a Docker-based operator.

## 2. Understanding AI Model Drift and its Implications

AI model drift refers to the degradation of a model's performance over time due to changes in the underlying data distributions or the relationships between input and output variables. While a model might perform excellently at the time of deployment, real-world conditions are dynamic, leading to its eventual decay.

**Why AI Model Drift is a Problem:**
*   **Degraded Performance:** A drifting model makes less accurate predictions or classifications, leading to poor decision-making.
*   **Financial Losses:** In financial applications, drift can lead to incorrect trading signals or fraud detection failures.
*   **Operational Inefficiency:** In industrial settings, it can cause machinery malfunctions or suboptimal resource allocation.
*   **Safety Concerns:** In critical systems (e.g., autonomous vehicles, medical diagnostics), drift can have severe, life-threatening consequences.
*   **Loss of Trust:** Users lose confidence in systems powered by unreliable AI.

**Common Causes of AI Model Drift:**
*   **Data Drift:** Changes in the distribution of input data. For example, a shift in customer demographics, economic conditions, or sensor readings.
*   **Concept Drift:** Changes in the relationship between the input variables and the target variable. This means the "rules" the model learned are no longer valid. For instance, consumer preferences evolving over time, or new types of fraud emerging.
*   **Upstream Data Changes:** Alterations in data collection methods, sensor calibrations, or data preprocessing pipelines.
*   **Seasonal/Temporal Changes:** Patterns that change with time (e.g., daily, weekly, yearly cycles) that the model wasn't trained to fully capture.
*   **Model Decay:** Over time, even without external changes, a model's internal parameters might degrade if not regularly retrained or updated.

My Drosera trap specifically addresses this critical challenge by providing an automated, on-chain mechanism to detect such drift and trigger a predefined response, ensuring the continuous reliability of AI models in decentralized applications.

## 3. Core Project Components

Here are the main smart contracts developed for this trap:

*   `AIMock.sol`: A basic mock contract (`src/AIMock.sol`) simulating an on-chain AI model. For dynamic testing, an `UpdatableAIMock.sol` is used.
*   `ITrap.sol`: The standard Drosera interface (`src/interfaces/ITrap.sol`) that my main trap contract implements.
*   `AIDriftTrap.sol`: My core trap logic (`src/AIDriftTrap.sol`). This contract implements the `collect()` and `shouldRespond()` functions to detect drift.
*   `AIConfig.sol`: A separate contract (`src/AIConfig.sol`) designed to hold immutable configuration parameters (like drift threshold and window size) for my stateless trap.
*   `ResponseContract.sol`: A contract (`src/ResponseContract.sol`) with a `handleDrift(string)` function, serving as the target for my trap's on-chain response. It includes access control.
*   `TrapRegistry.sol`: A central registry contract (`src/TrapRegistry.sol`) that stores and provides updatable addresses for other key contracts, enabling flexible configuration for the `AIDriftTrap`.

## 4. Key Challenges & Solutions

Building this trap involved navigating several non-trivial Drosera constraints and deployment issues.

### Challenge 1: Drosera Trap Contract Design (Statelessness & Pure Functions)

**Problem:** Drosera traps cannot have constructor arguments, and their `shouldRespond()` function must be `pure` (cannot read on-chain state). My initial `AIDriftTrap.sol` design violated these rules, and later, the hardcoded `AIConfig` address proved inflexible.

**My Solution:**
*   **Stateless `AIDriftTrap.sol`**: Refactored `AIDriftTrap.sol` to remove its constructor.
*   **`AIConfig.sol` for Configuration**: Introduced `AIConfig.sol` to store immutable configuration parameters.
*   **`TrapRegistry.sol` for Updatable Configuration**: Implemented a `TrapRegistry.sol` contract. `AIDriftTrap.sol` now reads its `AIConfig` address dynamically from this registry, allowing configuration updates without redeploying the trap.
*   **`collect()` for Data Provision**: Modified `collect()` to gather all necessary data (AI prediction, drift threshold) and `abi.encode` them.
*   **`shouldRespond()` as `pure`**: `shouldRespond()` decodes all its required data from `_collectOutputs`, allowing it to remain `pure`.

### Challenge 2: Securing the Response Contract

**Problem:** The `handleDrift()` function in `ResponseContract.sol` was public, meaning anyone could call it and spam the on-chain log.

**My Solution:**
*   Implemented access control in `ResponseContract.sol` using `onlyOwner` and `onlyDrosera` modifiers.
*   The contract owner (deployer) can set the authorized Drosera address, and only that address can call `handleDrift()`.

### Challenge 3: `drosera apply` Dry Run Bug with Registry Pattern

**Problem:** The `drosera apply` command performs a dry run that failed when the trap's `collect()` function attempted to read a dynamically configured address from the `TrapRegistry`. The dry run simulation consistently returned a stale/zero address, even though the address was correctly set on the live blockchain (verified with `cast call`).

**My Solution:**
*   This appears to be a bug in the `drosera` CLI tool's dry run environment.
*   We confirmed the on-chain state was correct. The `drosera apply` command eventually succeeded after multiple attempts, suggesting an intermittent caching or state synchronization issue within the tool.
*   A bug report has been prepared for the Drosera team.

### Challenge 4: General `drosera apply` Configuration & RPC Issues

**Problem:** Initial attempts to use `drosera apply` surfaced various configuration and network-related errors.

**My Solution:**
*   **Missing Network Configuration**: Ensured `drosera.toml` included explicit network details (`ethereum_rpc`, `drosera_rpc`, `eth_chain_id`, `drosera_address`).
*   **No Response Contract**: Created and deployed `ResponseContract.sol` and updated `drosera.toml` with its address and `handleDrift(string)` signature.
*   **`InvalidNumberOfOperators` for Private Traps**: Added my operator's public wallet address to the `whitelist` in `drosera.toml` for `private_trap = true`.
*   **New Trap vs. Update**: Learned that for a new trap, the `address` field in `drosera.toml` must be commented out for `drosera apply` to generate a new address.
*   **Unstable RPC Network Issues**: Switched to alternative RPC endpoints (e.g., `https://rpc.hoodi.ethpandaops.io`) in `drosera.toml` and restarted the Docker operator to ensure connectivity.

## 5. Deployment Workflow

The deployment process now leverages the `TrapRegistry` for flexible configuration:

1.  **Deploy `TrapRegistry.sol`**: Deploy the central registry contract.
2.  **Deploy `ResponseContract.sol`**: Deploy the response contract, initializing it with your wallet address for testing.
3.  **Deploy `UpdatableAIMock.sol`**: Deploy the mock AI model that allows its prediction to be changed.
4.  **Deploy `AIConfig.sol`**: Deploy the configuration contract, pointing it to the `UpdatableAIMock` address and setting the `driftThreshold`.
5.  **Update `AIDriftTrap.sol`**: Update the `TRAP_REGISTRY` constant in `AIDriftTrap.sol` with the address of your deployed `TrapRegistry`.
6.  **Compile Contracts**: `forge build` to compile all updated contracts.
7.  **Configure `TrapRegistry`**: Call `setAddress("AIConfig", <AIConfig_ADDRESS>)` on your deployed `TrapRegistry` to link it to your `AIConfig` contract.
8.  **Apply Trap Configuration**: `drosera apply` to register or update your trap on the Drosera network.

## 6. Operator Setup

I set up my Drosera operator using Docker to service my trap.

*   **Docker Compose:** I used `docker-compose.yaml` to define the operator service, linking it to my `.env` file for private keys and IP.
*   **Running Operator:** `docker compose up -d`.
*   **Registration:** I registered my operator with the Drosera network using a `docker run` command.
*   **Opt-in:** I opted my operator in to service my specific trap configuration using a `docker run` command.

## 7. End-to-End Test & Verification

To verify my trap, I simulated a drift event and observed the full end-to-end flow:

1.  **Triggering Drift:**
    *   Set `UpdatableAIMock` prediction to a non-drifting value (e.g., `50`, below `driftThreshold` of `100`).
    *   Set `UpdatableAIMock` prediction to a drifting value (e.g., `110`, above `driftThreshold` of `100`).

2.  **Monitoring Operator Logs:** I observed my operator logs (`docker logs drosera-operator`). The logs confirmed:
    *   My trap's `shouldRespond()` returned `true` when the prediction was `110`.
    *   My operator attempted to submit the claim to the network.
    *   Despite initial "nonce too low" errors (indicating operator wallet sync issues), the claim transaction (calling `handleDrift` on `ResponseContract`) was eventually `Successfully submitted`.

This end-to-end test provided conclusive evidence that my AI Drift Trap successfully detected the drift and triggered its on-chain response, with the updated `ResponseContract` handling the claim.

## 8. Comprehensive Testing of `shouldRespond`

To ensure the robustness and reliability of my trap's core on-chain logic, I developed a comprehensive test suite for the `shouldRespond()` function in `test/AIDriftTrap.t.sol`. These tests specifically cover the simplified direct threshold comparison now performed on-chain:

*   **No Drift:** Confirms `shouldRespond()` returns `false` when the latest prediction is below the defined threshold.
*   **Drift Detected:** Verifies `shouldRespond()` returns `true` and an appropriate message when the latest prediction exceeds the defined threshold.
*   **Edge Case (At Threshold):** Tests that `shouldRespond()` correctly returns `false` when the latest prediction is exactly at the threshold.
*   **Empty Data:** Confirms `shouldRespond()` handles an empty input array gracefully (e.g., by reverting).

The more complex drift detection logic, such as moving average calculations and handling of zero predictions, is now handled by the off-chain Drosera operator, as detailed in the "Key Challenges & Solutions" section.

All these tests are now passing, confirming the accurate and reliable behavior of the on-chain `shouldRespond()` function under diverse conditions.

## 9. Conclusion

This project successfully demonstrates the development and deployment of a custom AI parameter drift detection trap on the Drosera network. Despite encountering several platform-specific constraints and network challenges, I was able to implement a functional and verifiable solution.
