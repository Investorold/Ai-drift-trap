# My AI Parameter Drift Detection Trap Project

This repository documents the setup, deployment, and integration of a custom AI parameter drift detection trap and a ChatGPT analysis trap on the Hoodi Ethereum testnet. It highlights architectural decisions, solutions to challenges, and provides a comprehensive guide for replication.

## Table of Contents

1.  [Project Overview](#1-project-overview)
2.  [Prerequisites](#2-prerequisites)
3.  [Core Project Components](#3-core-project-components)
4.  [Drosera Trap Setup](#4-drosera-trap-setup)
    *   [Install Required Tools](#install-required-tools)
    *   [Initialize Trap Project](#initialize-trap-project)
    *   [Build Trap](#build-trap)
    *   [Trap Configuration (`drosera.toml`)](#trap-configuration-droseratoml)
    *   [Apply the Trap Config](#apply-the-trap-config)
5.  [Drosera Operator Setup](#5-drosera-operator-setup)
    *   [Install using Docker](#install-using-docker)
    *   [Register Your Operator](#register-your-operator)
    *   [Opt-in your trap config](#opt-in-your-trap-config)
6.  [End-to-End Test & Verification](#6-end-to-end-test--verification)
7.  [Key Challenges & Solutions](#7-key-challenges--solutions)
8.  [Comprehensive Testing of `shouldRespond`](#8-comprehensive-testing-of-shouldrespond)
9.  [ChatGPT Analysis Trap Setup](#9-chatgpt-analysis-trap-setup)
10. [Security Considerations](#10-security-considerations)
11. [Conclusion](#11-conclusion)

---

## 1. Project Overview

My goal was to create a Drosera trap that monitors an on-chain AI model's predictions for significant "drift" and triggers an on-chain response when detected. This project evolved to include a second trap for analyzing ChatGPT data. It involved developing custom Solidity contracts, configuring Drosera's `drosera.toml`, and setting up a Docker-based operator.

## 2. Prerequisites

*   Ubuntu/Linux environment (WSL Ubuntu works well)
*   At least 4 CPU cores and 8GB RAM recommended
*   Basic CLI knowledge
*   Ethereum private key with funds on Hoodi testnet
*   Open ports: 31313 and 31314 (or your configured ports)
*   OpenAI API Key (may require a paid plan for access)

### Hoodi Testnet ETH (Hoodi Token)

To mine or interact with contracts on the Hoodi Testnet, you'll need test ETH:

*   **Faucet Links:**
    *   Mining Faucet: `https://hoodi-faucet.pk910.de`
    *   Public Faucets: QuickNode Faucet, Stakely Faucet
*   **Hoodi Testnet Details:** `https://github.com/eth-clients/hoodi`

## 3. Core Project Components

Here are the main smart contracts developed for this project:

*   `AIMock.sol`: A basic mock contract (`src/AIMock.sol`) simulating an on-chain AI model. For dynamic testing, an `UpdatableAIMock.sol` is used.
*   `ITrap.sol`: The standard Drosera interface (`src/interfaces/ITrap.sol`) that my main trap contracts implement.
*   `AIDriftTrap.sol`: My core trap logic (`src/AIDriftTrap.sol`). This contract implements the `collect()` and `shouldRespond()` functions to detect numerical drift.
*   `AIConfig.sol`: A separate contract (`src/AIConfig.sol`) designed to hold immutable configuration parameters (like drift threshold) for my stateless trap.
*   `ResponseContract.sol`: A contract (`src/ResponseContract.sol`) with `handleDrift(string)` and `respond(bytes)` functions, serving as the target for my traps' on-chain responses. It includes access control.
*   `TrapRegistry.sol`: A central registry contract (`src/TrapRegistry.sol`) that stores and provides updatable addresses for other key contracts, enabling flexible configuration for the `AIDriftTrap`.
*   `ChatGPTAnalysisTrap.sol`: A new trap (`src/ChatGPTAnalysisTrap.sol`) designed to analyze encoded ChatGPT data on-chain.
*   `ChatGPTInfoStore.sol`: A contract (`src/ChatGPTInfoStore.sol`) to store encoded ChatGPT information on-chain, serving as the data source for `ChatGPTAnalysisTrap`.

### Trap Types and Their Roles

This project features two distinct types of Drosera traps, each designed for different data analysis needs:

*   **AI Drift Trap (`AIDriftTrap.sol`):**
    *   **Purpose:** Detects numerical drift in AI model predictions.
    *   **Data Source:** Reads numerical prediction data from `AIMock.sol` (configured via `AIConfig.sol`).
    *   **Analysis:** `shouldRespond()` compares the latest prediction against a defined `driftThreshold`.
    *   **Response:** Triggers `handleDrift(string)` on the `ResponseContract.sol`.

*   **ChatGPT Analysis Trap (`ChatGPTAnalysisTrap.sol`):**
    *   **Purpose:** Analyzes encoded textual/binary data from ChatGPT.
    *   **Data Source:** Reads encoded ChatGPT information from `ChatGPTInfoStore.sol` (populated by an off-chain Python service).
    *   **Analysis:** `shouldRespond()` performs analysis on the encoded data (e.g., checking for non-empty data as a basic drift indicator).
    *   **Response:** Triggers `respond(bytes)` on the `ResponseContract.sol`.

Both traps implement the `ITrap` interface, demonstrating the flexibility of the Drosera protocol to monitor various types of on-chain data and trigger different response functions.

## 4. Drosera Trap Setup

### Install Required Tools

```bash
# Drosera CLI
curl -L https://app.drosera.io/install | bash
source ~/.bashrc
droseraup

# Foundry CLI (Solidity development)
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc
foundryup

# Bun (JavaScript runtime) - if needed for template
curl -fsSL https://bun.sh/install | bash
source ~/.bashrc
```

### Initialize Trap Project

```bash
mkdir ~/my-drosera-trap
cd ~/my-drosera-trap

git config --global user.email "your_github_email@example.com"
git config --global user.name "your_github_username"

forge init -t drosera-network/trap-foundry-template
```

### Build Trap

```bash
bun install # If template uses bun
forge build
```

### Trap Configuration (`drosera.toml`)

Edit your `drosera.toml` file (`nano drosera.toml`) to include the following configurations. Replace placeholder addresses with your deployed contract addresses and your operator's whitelisted address.

```toml
ethereum_rpc = "https://0xrpc.io/hoodi"
drosera_rpc = "https://relay.hoodi.drosera.io"
eth_chain_id = 560048
drosera_address = "0x91cB447BaFc6e0EA0F4Fe056F5a9b1F14bb06e5D"

# ---
# TRAP 1: The original AI Drift Trap
# ---
[traps.ai_drift_trap]
name = "AI Drift Trap"
description = "Monitors a numerical value for drift."
path = "out/AIDriftTrap.sol/AIDriftTrap.json"
response_contract = "0x56a0C23256F9234EE79f6c98066B1B92faCb6eb7"
response_function = "handleDrift(string)"
cooldown_period_blocks = 33
min_number_of_operators = 1
max_number_of_operators = 2
block_sample_size = 100
private_trap = true
whitelist = ["0x018Ecd0cC400C083a74E44a69056D82Adb089F41"] # Replace with your operator's address
address = "0x1bc6A7EDC145C3A116C646cd81D3a4be1C0a8161" # Replace with your deployed AIDriftTrap address

[traps.ai_drift_trap.functions]
collect = "collect()"
should_respond = "shouldRespond(bytes[])"

# ---
# TRAP 2: ChatGPT Analysis Trap
# ---
[traps.chatgpt_analysis_trap]
name = "ChatGPT Analysis Trap"
description = "A trap that analyzes encoded ChatGPT data on-chain."
path = "out/ChatGPTAnalysisTrap.sol/ChatGPTAnalysisTrap.json"
response_contract = "0x7Ac5426B0D22786bF96AE5e4eeB9132F2926235F" # Replace with your deployed ResponseContract address
response_function = "respond(bytes)"
cooldown_period_blocks = 33 # Adjust as needed
min_number_of_operators = 1
max_number_of_operators = 2 # Adjust as needed
block_sample_size = 100 # Adjust as needed
private_trap = true
whitelist = ["0x018Ecd0cC400C083a74E44a69056D82Adb089F41"] # Replace with your operator's address
address = "0x90f8dEAd8735282F339a1d8E356EF80ab68C902A" # Replace with your deployed Trap Config address (if updating) or delete for new deployment

[traps.chatgpt_analysis_trap.functions]
collect = "collect()"
should_respond = "shouldRespond(bytes[])"
```

### Apply the Trap Config

This command registers or updates your trap configuration on the Drosera network. Ensure your private key is funded on Hoodi testnet.

```bash
DROSERA_PRIVATE_KEY=your_eth_private_key_here drosera apply
```

*   **New Trap Deployment:** If `address` is deleted from `drosera.toml`, `drosera apply` will output a new Trap Config address.
*   **Updating Existing Trap:** If `address` is set to an existing Trap Config address, `drosera apply` will update that trap.

## 5. Drosera Operator Setup

I set up my Drosera operator using Docker to service my trap.

### Install using Docker

(Refer to official Drosera documentation for detailed Docker setup: `https://dev.drosera.io/operators/run-operator`)

### Register Your Operator

```bash
drosera-operator register \
  --eth-rpc-url https://0xrpc.io/hoodi \
  --eth-private-key your_eth_private_key_here \
  --drosera-address 0x91cB447BaFc6e0EA0F4Fe056F5a9b1F14bb06e5D
```

### Opt-in your trap config

```bash
drosera-operator optin \
  --eth-rpc-url https://0xrpc.io/hoodi \
  --eth-private-key your_eth_private_key_here \
  --trap-config-address your_trap_config_address_here
```

## 6. End-to-End Test & Verification

To verify my traps, I simulated drift events and observed the full end-to-end flow:

### Triggering Drift (AI Drift Trap)

*   Set `UpdatableAIMock` prediction to a non-drifting value (e.g., `50`, below `driftThreshold` of `100`).
*   Set `UpdatableAIMock` prediction to a drifting value (e.g., `110`, above `driftThreshold` of `100`).

### Triggering Drift (ChatGPT Analysis Trap)

1.  **Deploy Contracts:** Ensure `ChatGPTAnalysisTrap.sol`, `ChatGPTInfoStore.sol`, and `ResponseContract.sol` are deployed on the Hoodi testnet.
2.  **Set up `scripts/chatgpt_service/.env`:**
    *   Navigate to `scripts/chatgpt_service/`.
    *   Create a file named `.env` (if it doesn't exist).
    *   Add the following lines, replacing the placeholders with your actual values:
        ```
        RPC_URL=https://0xrpc.io/hoodi
        PRIVATE_KEY=YOUR_ETHEREUM_PRIVATE_KEY_FOR_TRANSACTIONS # This key will be used to send transactions to ChatGPTInfoStore
        CHATGPT_INFO_STORE_ADDRESS=YOUR_DEPLOYED_CHATGPT_INFO_STORE_CONTRACT_ADDRESS
        OPENAI_API_KEY=YOUR_OPENAI_API_KEY
        ```
    *   **Important Note on `OPENAI_API_KEY`:** The OpenAI API requires a paid plan for reliable access. Free-tier keys are often heavily rate-limited or may not work. Ensure your account has a valid billing plan to avoid API errors.
3.  **Run the Service:**
    *   From the project root, execute: `python3 scripts/chatgpt_service/main.py`
    *   This script will fetch data from ChatGPT, encode it, and update your `ChatGPTInfoStore` contract on-chain, simulating a drift event.

### Monitoring Operator Logs

I observed my operator logs (`docker logs drosera-operator`). The logs confirmed:

*   My trap's `shouldRespond()` returned `true` when drift was detected.
*   My operator attempted to submit the claim to the network.
*   Despite initial "nonce too low" errors (indicating operator wallet sync issues), the claim transaction (calling `handleDrift` or `respond` on `ResponseContract`) was eventually `Successfully submitted`.

This end-to-end test provided conclusive evidence that my AI Drift Trap and ChatGPT Analysis Trap successfully detected drift and triggered their on-chain responses.

## 7. Key Challenges & Solutions

Building this project involved navigating several non-trivial Drosera constraints and deployment issues.

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
*   The contract owner (deployer) can set the authorized Drosera address, and only that address can call `handleDrift()` or `respond()`.

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
*   **Unstable RPC Network Issues**: Switched to alternative RPC endpoints (e.g., `https://0xrpc.io/hoodi`) in `drosera.toml` for improved stability.

## 8. Comprehensive Testing of `shouldRespond`

To ensure the robustness and reliability of my trap's core on-chain logic, I developed a comprehensive test suite for the `shouldRespond()` function in `test/AIDriftTrap.t.sol`. These tests specifically cover the simplified direct threshold comparison now performed on-chain:

*   **No Drift:** Confirms `shouldRespond()` returns `false` when the latest prediction is below the defined threshold.
*   **Drift Detected:** Verifies `shouldRespond()` returns `true` and an appropriate message when the latest prediction exceeds the defined threshold.
*   **Edge Case (At Threshold):** Tests that `shouldRespond()` correctly returns `false` when the latest prediction is exactly at the threshold.
*   **Empty Data:** Confirms `shouldRespond()` handles an empty input array gracefully (e.g., by reverting).

The more complex drift detection logic, such as moving average calculations and handling of zero predictions, is now handled by the off-chain Drosera operator, as detailed in the "Key Challenges & Solutions" section.

All these tests are now passing, confirming the accurate and reliable behavior of the on-chain `shouldRespond()` function under diverse conditions.

## 9. Security Considerations

While this is a test project, here are some security considerations:

*   **Private Key and API Key Handling:** Sensitive keys are stored in `.env` files. For production, use secure key management solutions.
*   **Access Control:** Contracts use `onlyOwner` and `onlyDrosera` modifiers for sensitive functions, which is good practice. The security relies heavily on the `owner`'s private key.
*   **Trap Logic (`shouldRespond()`):** The core analysis logic needs rigorous testing and potentially formal verification for production use to prevent manipulation or incorrect behavior.
*   **Hardcoded Addresses:** Addresses are hardcoded in Solidity contracts for simplicity. For production, consider more flexible configuration patterns.

## 10. Conclusion

This project successfully demonstrates the implementation and deployment of a Drosera AI Drift Trap, including integration with external AI services like ChatGPT. It highlights solutions to common challenges in building and configuring Drosera traps, providing a robust foundation for further development.