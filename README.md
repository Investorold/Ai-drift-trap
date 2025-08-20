# My AI Parameter Drift Detection Trap Project

This repository documents my journey in building and deploying a custom AI parameter drift detection trap on the Drosera network. This project highlights the key architectural decisions and solutions to significant challenges encountered during development and deployment.

## Table of Contents

1.  [Project Overview](#1-project-overview)
2.  [Core Project Components](#2-core-project-components)
3.  [Key Challenges & Solutions](#3-key-challenges--solutions)
4.  [Deployment Workflow](#4-deployment-workflow)
5.  [Operator Setup](#5-operator-setup)
6.  [End-to-End Test & Verification](#6-end-to-end-test--verification)
7.  [Conclusion](#7-conclusion)

---

## 1. Project Overview

My goal was to create a Drosera trap that monitors an on-chain AI model's predictions for significant "drift" and triggers an on-chain response when detected. This project involved developing custom Solidity contracts, configuring Drosera's `drosera.toml`, and setting up a Docker-based operator.

## 2. Core Project Components

Here are the main smart contracts developed for this trap:

*   `AIMock.sol`: A basic mock contract (`src/AIMock.sol`) simulating an on-chain AI model, providing dummy prediction data.
*   `ITrap.sol`: The standard Drosera interface (`src/interfaces/ITrap.sol`) that my main trap contract implements.
*   `AIDriftTrap.sol`: My core trap logic (`src/AIDriftTrap.sol`). This contract implements the `collect()` and `shouldRespond()` functions to detect drift.
*   `AIConfig.sol`: A separate contract (`src/AIConfig.sol`) designed to hold immutable configuration parameters (like drift threshold and window size) for my stateless trap.
*   `ResponseContract.sol`: A simple contract (`src/ResponseContract.sol`) with a `handleDrift(string)` function, serving as the target for my trap's on-chain response.

## 3. Key Challenges & Solutions

Building this trap involved navigating several non-trivial Drosera constraints and deployment issues.

### Challenge 1: Drosera Trap Contract Design (No Constructors, Pure Functions)

**Problem:** I learned that Drosera traps cannot have constructor arguments and their `shouldRespond()` function must be pure (meaning it cannot read any on-chain state). My initial `AIDriftTrap.sol` design violated these rules.

**My Solution:**
*   **Stateless `AIDriftTrap.sol`**: I refactored `AIDriftTrap.sol` to remove its constructor.
*   **`AIConfig.sol` for Configuration**: I introduced `AIConfig.sol` to store immutable configuration parameters. `AIDriftTrap.sol` now reads its configuration by calling view functions on a hardcoded `AIConfig` address.
*   **`collect()` for Data Provision**: I modified `collect()` to gather all necessary data (AI prediction, drift threshold, and window size) and `abi.encode` them together.
*   **`shouldRespond()` as `pure`**: `shouldRespond()` now decodes all its required data from the `_collectOutputs` argument, allowing it to remain pure as required.

(Note: The specific drift detection logic within `shouldRespond()` is my custom "blueprint" and is not detailed here.)

### Challenge 2: `drosera apply` Configuration Errors

The `drosera apply` command, which registers the trap with the network, surfaced several configuration-related errors.

*   **Missing Network Configuration**: `drosera.toml` required explicit network details (`ethereum_rpc`, `drosera_rpc`, `eth_chain_id`, `drosera_address`).
*   **No Response Contract**: The trap needed a valid contract to call when it responded.
    *   **Solution**: I created and deployed `ResponseContract.sol` and updated `drosera.toml` with its address and the `handleDrift(string)` function signature.
*   **`InvalidNumberOfOperators` for Private Traps**: My trap was set as `private_trap = true`, but the whitelist of operators was empty.
    *   **Solution**: I added my operator's public wallet address to the `whitelist` in `drosera.toml`.
*   **New Trap vs. Update**: I learned that for a new trap, the `address` field in `drosera.toml` must be commented out. `drosera apply` will then generate and write the new trap address.

### Challenge 3: Unstable RPC Network Issues

**Problem:** I frequently encountered network errors (Cloudflare blocks, 502s, `tx not found`) when interacting with the Hoodi testnet RPCs, which hindered deployment and verification.

**My Solution:** I switched to alternative RPC endpoints (e.g., `https://0xrpc.io/hoodi`) in `drosera.toml` and restarted my Docker operator to ensure connectivity.

## 4. Deployment Workflow

My deployment process involved a specific sequence due to the hardcoded `AIConfig` address:

1.  **Deploy `UpdatableAIMock.sol`**: Deployed to `0x94348BE1772b08dFD2f00eEa21725D2264EA25bE`.
2.  **Deploy `AIConfig.sol`**: Deployed a new instance pointing to `UpdatableAIMock` at `0x71dd5e8E61eB56A536e9073cbeAf6b9649049154`.
3.  **Update `AIDriftTrap.sol`**: Manually updated the `AI_CONFIG_ADDRESS` constant in `AIDriftTrap.sol` to `0x71dd5e8E61eB56A536e9073cbeAf6b9649049154`.
4.  **Compile `AIDriftTrap.sol`**: `forge build`.
5.  **Apply Trap Configuration**: `drosera apply` created my new trap config at `0x1bc6A7EDC145C3A116C646cd81D3a4be1C0a8161`.

## 5. Operator Setup

I set up my Drosera operator using Docker to service my trap.

*   **Docker Compose:** I used `docker-compose.yaml` to define the operator service, linking it to my `.env` file for private keys and IP.
*   **Running Operator:** `docker compose up -d`.
*   **Registration:** I registered my operator with the Drosera network using a `docker run` command.
*   **Opt-in:** I opted my operator in to service my specific trap configuration using a `docker run` command.

## 6. End-to-End Test & Verification

To verify my trap, I simulated a drift event:

1.  **Triggering Drift:** I called `setPrediction(200)` on my deployed `UpdatableAIMock` contract (initial value was 123).
2.  **Monitoring Operator Logs:** I observed my operator logs (`docker compose logs -f`). The logs confirmed:
    *   My trap's `shouldRespond()` returned `true`.
    *   My operator was selected to submit the claim.
    *   The claim transaction (calling `handleDrift` on `ResponseContract`) was `Successfully submitted`.

While RPC instability prevented direct verification of the `ResponseContract`'s updated message via `cast call`, the operator logs provided conclusive evidence that my AI Drift Trap successfully detected the drift and triggered its on-chain response.

## 7. Conclusion

This project successfully demonstrates the development and deployment of a custom AI parameter drift detection trap on the Drosera network. Despite encountering several platform-specific constraints and network challenges, I was able to implement a functional and verifiable solution.