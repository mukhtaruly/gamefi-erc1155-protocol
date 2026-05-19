
# gamefi-erc1155-protocol

## Project Topic
We selected **Option B — GameFi Economy**.

This project implements a decentralized in-game economy using blockchain technology.  
It includes ERC-1155 items, crafting, marketplace (AMM), NFT rental, Chainlink VRF, and DAO governance.

---

## Project Description
The goal is to build a full-stack GameFi protocol where:
- Players own in-game items (ERC-1155)
- Items can be crafted from resources
- Resources can be traded using AMM
- NFTs can be rented
- Loot drops are randomized using Chainlink VRF
- Game parameters are controlled by DAO

---

## Team Members & Responsibilities

### Нурасыл (Backend / Smart Contracts)
- ERC-1155 contract (GameItems)
- AMM marketplace (x * y = k)
- Crafting system
- Writing tests (Foundry)
- Security fixes

---

### Мирас (Frontend / Integration)
- Frontend (React + Wagmi)
- Wallet connection
- UI for crafting, trading, renting
- Integration with smart contracts

---

### Алихан (Infrastructure / Data / Deployment)
- The Graph (subgraph)
- Chainlink integration (VRF + price feeds)
- L2 deployment (testnet)
- CI/CD setup (GitHub Actions)

---

## Roadmap

### Week 6
- Repository setup
- Planning
- Initial contract

### Week 7
- ERC-1155 implementation
- Unit tests

### Week 8
- AMM implementation
- Crafting system

### Week 9
- DAO governance
- Chainlink integration
- L2 deployment

### Week 10
- Frontend completion
- Testing
- Audit report
- Final presentation

---

## Tech Stack
- Solidity (Foundry)
- OpenZeppelin
- Chainlink
- React + Wagmi
- The Graph

---

# GameFi Economy Protocol

## Overview

GameFi Economy Protocol is a decentralized blockchain-based game economy built with Solidity and Foundry.

The protocol combines:

- ERC20 governance token
- ERC1155 game items
- Crafting system
- AMM resource exchange
- DAO governance
- NFT loot mechanics
- Vault system

The project was developed as a Blockchain Technologies 2 Final Project.

---

# Architecture

## Core Contracts

| Contract | Description |
|---|---|
| GameToken.sol | ERC20 governance token with ERC20Votes |
| GameItems.sol | ERC1155 game items |
| ResourceAMM.sol | Constant-product AMM |
| CraftingRules.sol | Crafting logic |
| GameGovernor.sol | DAO governance |
| LootChest.sol | Loot reward mechanics |
| RentalVault.sol | Asset vault |

---

# Features

- ERC20Votes governance
- ERC1155 items
- Crafting system
- AMM token swaps
- Proposal voting
- MetaMask integration
- L2-ready deployment
- Foundry test suite

---

# Tech Stack

- Solidity
- Foundry
- OpenZeppelin
- Vite
- TypeScript
- Ethers.js
- MetaMask

---

# Installation

## Clone repository

```bash
git clone <repo-url>
cd gamefi-erc1155-protocol