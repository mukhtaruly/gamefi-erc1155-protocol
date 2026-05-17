
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

## Status
🟡 Week 6 — In Progress
=======
# GameFi Economy Protocol

Production-style Foundry implementation for **Option B - GameFi Economy**.

The protocol combines ERC1155 game assets, crafting, AMM resource trading, DAO governance, an ERC4626 rental vault, deterministic deployments, UUPS upgradeability, Chainlink VRF-compatible loot chests, frontend, subgraph, CI, and deployment scripts.

## Architecture

- `GameItems`: ERC1155 resources and crafted items with role-based minting.
- `GameToken`: ERC20Votes governance and economy token.
- `ResourceAMM`: constant-product AMM with 0.3% fee, LP shares, bidirectional swaps, slippage protection, CEI, and invariant checks.
- `LPToken`: AMM-owned ERC20 LP share token.
- `RentalVault`: ERC4626 vault for payment assets plus ERC1155 rental escrow.
- `GameGovernor`: OpenZeppelin Governor with 4% quorum, 1% proposal threshold, 1 day voting delay, 1 week voting period.
- `TimelockController`: 2 day execution delay for DAO-controlled operations.
- `GameTreasury`: token treasury with explicit accounting checks.
- `CraftingRules`: UUPS-upgradeable recipe configuration.
- `ProtocolFactory`: CREATE2 deployments for AMMs and UUPS proxies.
- `VRFLootChest`: Chainlink VRF-compatible random loot minting.

## Commands

```shell
forge fmt --check
forge build
forge test
forge coverage --summary --ir-minimum --exclude-tests --no-match-coverage "script|test"
```

Run Slither locally:

```shell
slither . --filter-paths "lib|test|script"
```

## Deployment

Base Sepolia:

```shell
forge script script/DeployProtocol.s.sol:DeployProtocol \
  --rpc-url "$BASE_SEPOLIA_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --broadcast \
  --verify
```

Arbitrum Sepolia:

```shell
forge script script/DeployProtocol.s.sol:DeployProtocol \
  --rpc-url "$ARBITRUM_SEPOLIA_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --broadcast \
  --verify
```

Useful environment variables:

- `DEPLOYER`
- `VRF_COORDINATOR`
- `VRF_KEY_HASH`
- `VRF_SUBSCRIPTION_ID`
- `BASE_SEPOLIA_RPC_URL`
- `ARBITRUM_SEPOLIA_RPC_URL`
- `PRIVATE_KEY`

## Frontend

```shell
cd frontend
npm install
npm run dev
```

Set deployed addresses with:

```shell
VITE_GAME_TOKEN=0x...
VITE_GAME_ITEMS=0x...
VITE_RESOURCE_AMM=0x...
VITE_GOVERNOR=0x...
```

## Subgraph

```shell
cd subgraph
npm install
npm run codegen
npm run build
```

For a single deployed instance, add deployed contract addresses and start blocks to each `source` section in `subgraph/subgraph.yaml`.

## Testing Scope

- Unit tests for ERC20Votes, ERC1155 crafting, AMM, treasury, rental vault, CREATE2 factory, VRF loot, and governance lifecycle.
- Fuzz coverage through AMM bounded swap tests and invariant handler calls.
- Invariants for AMM `x*y=k` safety and ERC20 supply conservation.
- Fork deployment-shape test for Base Sepolia when `BASE_SEPOLIA_RPC_URL` is available.

## Security Posture

- Uses OpenZeppelin primitives for ERC20Votes, ERC1155, ERC4626, Governor, Timelock, AccessControl, UUPS, and proxy deployment.
- Uses `SafeERC20` for custody-moving ERC20 flows.
- Uses `ReentrancyGuard` on external state-changing flows that transfer tokens.
- Uses role-based permissions for minting, treasury, factory, upgrade, VRF config, and vault curation.
- Avoids `tx.origin`, `transfer`, and `send`.
- Applies CEI in AMM, treasury, rental, and loot flows.
 9bc2ee0 (Complete GameFi ERC1155 protocol with governance and security testing)
