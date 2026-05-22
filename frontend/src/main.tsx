import React, { useMemo, useState } from "react";
import { createRoot } from "react-dom/client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { defineChain, formatEther, parseEther } from "viem";
import {
  WagmiProvider,
  createConfig,
  http,
  useAccount,
  useBalance,
  useConnect,
  useReadContract,
  useSwitchChain,
  useWriteContract
} from "wagmi";
import { injected } from "wagmi/connectors";
import "./styles.css";

/* ── Chain config ──────────────────────────────────────────── */
const anvil = defineChain({
  id: 31337,
  name: "Anvil Local",
  nativeCurrency: { name: "Ether", symbol: "ETH", decimals: 18 },
  rpcUrls: { default: { http: ["http://127.0.0.1:8545"] } }
});

const config = createConfig({
  chains: [anvil],
  connectors: [injected()],
  transports: { [anvil.id]: http("http://127.0.0.1:8545") }
});

function contractAddress(name: string): `0x${string}` {
  const value = import.meta.env[name];
  if (!value || !/^0x[a-fA-F0-9]{40}$/.test(value))
    throw new Error(`${name} is missing in .env`);
  return value as `0x${string}`;
}

const addresses = {
  gameToken: contractAddress("VITE_GAME_TOKEN"),
  gameItems: contractAddress("VITE_GAME_ITEMS"),
  amm: contractAddress("VITE_RESOURCE_AMM"),
  governor: contractAddress("VITE_GOVERNOR")
};

/* ── ABIs ──────────────────────────────────────────────────── */
const erc20Abi = [
  { type: "function", name: "balanceOf", stateMutability: "view",
    inputs: [{ name: "account", type: "address" }], outputs: [{ type: "uint256" }] },
  { type: "function", name: "approve", stateMutability: "nonpayable",
    inputs: [{ name: "spender", type: "address" }, { name: "amount", type: "uint256" }],
    outputs: [{ type: "bool" }] },
  { type: "function", name: "delegate", stateMutability: "nonpayable",
    inputs: [{ name: "delegatee", type: "address" }], outputs: [] }
] as const;

const itemsAbi = [
  { type: "function", name: "balanceOf", stateMutability: "view",
    inputs: [{ name: "account", type: "address" }, { name: "id", type: "uint256" }],
    outputs: [{ type: "uint256" }] },
  { type: "function", name: "craftSword", stateMutability: "nonpayable",
    inputs: [], outputs: [] }
] as const;

const ammAbi = [
  { type: "function", name: "reserveA", stateMutability: "view",
    inputs: [], outputs: [{ type: "uint256" }] },
  { type: "function", name: "reserveB", stateMutability: "view",
    inputs: [], outputs: [{ type: "uint256" }] },
  { type: "function", name: "swapAForB", stateMutability: "nonpayable",
    inputs: [{ name: "amountIn", type: "uint256" }, { name: "minAmountOut", type: "uint256" }],
    outputs: [{ type: "uint256" }] }
] as const;

const governorAbi = [
  { type: "function", name: "castVote", stateMutability: "nonpayable",
    inputs: [{ name: "proposalId", type: "uint256" }, { name: "support", type: "uint8" }],
    outputs: [{ type: "uint256" }] }
] as const;

/* ── Helpers ───────────────────────────────────────────────── */
function fmt(v: bigint | undefined, decimals = 18): string {
  if (v === undefined) return "—";
  const s = formatEther(v);
  const n = parseFloat(s);
  return n >= 1000
    ? n.toLocaleString(undefined, { maximumFractionDigits: 2 })
    : n.toFixed(4);
}

function shortAddr(addr: string): string {
  return `${addr.slice(0, 6)}…${addr.slice(-4)}`;
}

/* ── App ───────────────────────────────────────────────────── */
function App() {
  const { address, chain } = useAccount();
  const { connect, connectors } = useConnect();
  const { switchChain, chains } = useSwitchChain();
  const { writeContractAsync, error, isPending } = useWriteContract();

  const [swapAmount, setSwapAmount] = useState("1");
  const [proposalId, setProposalId] = useState("");

  /* Reads */
  const nativeBal = useBalance({ address });

  const gameBal = useReadContract({
    address: addresses.gameToken, abi: erc20Abi,
    functionName: "balanceOf", args: address ? [address] : undefined,
    query: { enabled: Boolean(address) }
  });

  const woodBal = useReadContract({
    address: addresses.gameItems, abi: itemsAbi,
    functionName: "balanceOf", args: address ? [address, 1n] : undefined,
    query: { enabled: Boolean(address) }
  });

  const ironBal = useReadContract({
    address: addresses.gameItems, abi: itemsAbi,
    functionName: "balanceOf", args: address ? [address, 2n] : undefined,
    query: { enabled: Boolean(address) }
  });

  const swordBal = useReadContract({
    address: addresses.gameItems, abi: itemsAbi,
    functionName: "balanceOf", args: address ? [address, 3n] : undefined,
    query: { enabled: Boolean(address) }
  });

  const reserveA = useReadContract({ address: addresses.amm, abi: ammAbi, functionName: "reserveA" });
  const reserveB = useReadContract({ address: addresses.amm, abi: ammAbi, functionName: "reserveB" });

  const errorMsg = useMemo(() => error?.message ?? "", [error]);

  /* Writes */
  const approveAmm   = () => writeContractAsync({ address: addresses.gameToken, abi: erc20Abi,
    functionName: "approve", args: [addresses.amm, parseEther("1000000")] });
  const swapAForB    = () => writeContractAsync({ address: addresses.amm, abi: ammAbi,
    functionName: "swapAForB", args: [parseEther(swapAmount), 0n] });
  const craftSword   = () => writeContractAsync({ address: addresses.gameItems, abi: itemsAbi,
    functionName: "craftSword" });
  const delegateVotes = () => address && writeContractAsync({ address: addresses.gameToken, abi: erc20Abi,
    functionName: "delegate", args: [address] });
  const voteForProp  = () => proposalId && writeContractAsync({ address: addresses.governor, abi: governorAbi,
    functionName: "castVote", args: [BigInt(proposalId), 1] });

  return (
    <main>
      {/* ── Header ── */}
      <header className="hud-header">
        <div className="brand">
          <span className="brand-title">GameFi Protocol</span>
          <span className="brand-sub">ERC-1155 · On-Chain Economy</span>
        </div>

        <div className="wallet-status">
          {address ? (
            <>
              <div className="chain-badge">{chain?.name ?? "unknown"}</div>
              <div className="wallet-chip">
                <span className="wallet-dot" />
                <span>{shortAddr(address)}</span>
              </div>
            </>
          ) : (
            <button
              className="hud-btn hud-btn--connect"
              style={{ flex: "none", minWidth: 160 }}
              onClick={() => connect({ connector: connectors[0] })}
            >
              ⚡ Connect Wallet
            </button>
          )}
        </div>
      </header>

      {/* ── Network switch ── */}
      {chains.length > 0 && (
        <div className="network-bar">
          <span className="network-label">Network:</span>
          {chains.map((t) => (
            <button
              key={t.id}
              className="hud-btn hud-btn--primary"
              style={{ flex: "none", height: 32, fontSize: 11, padding: "0 14px" }}
              onClick={() => switchChain({ chainId: t.id })}
            >
              {t.name}
            </button>
          ))}
        </div>
      )}

      {/* ── TX pending indicator ── */}
      {isPending && (
        <div className="tx-indicator" style={{ marginBottom: 20 }}>
          <span className="spinner" />
          Broadcasting transaction…
        </div>
      )}

      {/* ── Panels grid ── */}
      <div className="panel-grid">

        {/* Balances */}
        <section className="panel panel--balances">
          <div className="panel-header">
            <div className="panel-icon">💰</div>
            <div>
              <div className="panel-title">Inventory</div>
              <div className="panel-desc">wallet · assets</div>
            </div>
          </div>
          <div className="stat-list">
            <div className="stat-row">
              <span className="stat-label"><span className="stat-icon">⟠</span> ETH</span>
              <span className="stat-value stat-value--eth">
                {nativeBal.data ? fmt(nativeBal.data.value) : "—"}
              </span>
            </div>
            <div className="stat-row">
              <span className="stat-label"><span className="stat-icon">🪙</span> GTK</span>
              <span className="stat-value stat-value--gtk">
                {gameBal.data !== undefined ? fmt(gameBal.data) : "—"}
              </span>
            </div>
            <div className="stat-row">
              <span className="stat-label"><span className="stat-icon">🪵</span> Wood</span>
              <span className="stat-value stat-value--wood">
                {woodBal.data?.toString() ?? "—"}
              </span>
            </div>
            <div className="stat-row">
              <span className="stat-label"><span className="stat-icon">🔩</span> Iron</span>
              <span className="stat-value stat-value--iron">
                {ironBal.data?.toString() ?? "—"}
              </span>
            </div>
            <div className="stat-row">
              <span className="stat-label"><span className="stat-icon">⚔️</span> Sword</span>
              <span className="stat-value stat-value--sword">
                {swordBal.data?.toString() ?? "—"}
              </span>
            </div>
          </div>
        </section>

        {/* AMM */}
        <section className="panel panel--amm">
          <div className="panel-header">
            <div className="panel-icon">⚗️</div>
            <div>
              <div className="panel-title">Resource AMM</div>
              <div className="panel-desc">liquidity · swap</div>
            </div>
          </div>
          <div className="reserve-grid">
            <div className="reserve-card">
              <div className="reserve-label">Reserve A</div>
              <div className="reserve-value">{reserveA.data !== undefined ? fmt(reserveA.data) : "—"}</div>
            </div>
            <div className="reserve-card">
              <div className="reserve-label">Reserve B</div>
              <div className="reserve-value">{reserveB.data !== undefined ? fmt(reserveB.data) : "—"}</div>
            </div>
          </div>
          <div className="swap-form">
            <div>
              <label className="input-label">Swap Amount (GTK)</label>
              <input
                className="hud-input"
                value={swapAmount}
                onChange={(e) => setSwapAmount(e.target.value)}
                placeholder="0.0"
              />
            </div>
            <div className="btn-row">
              <button className="hud-btn hud-btn--gold" disabled={isPending} onClick={approveAmm}>
                ✓ Approve
              </button>
              <button className="hud-btn hud-btn--primary" disabled={isPending} onClick={swapAForB}>
                ⇄ Swap A→B
              </button>
            </div>
          </div>
        </section>

        {/* Crafting */}
        <section className="panel panel--crafting">
          <div className="panel-header">
            <div className="panel-icon">🔨</div>
            <div>
              <div className="panel-title">Forge</div>
              <div className="panel-desc">crafting · items</div>
            </div>
          </div>
          <div className="craft-area">
            <div className="craft-recipe">
              <div className="recipe-item">
                <span className="recipe-emoji">🪵</span>
                <span className="recipe-name">Wood</span>
                <span className="recipe-qty">×5</span>
              </div>
              <span className="recipe-plus">+</span>
              <div className="recipe-item">
                <span className="recipe-emoji">🔩</span>
                <span className="recipe-name">Iron</span>
                <span className="recipe-qty">×3</span>
              </div>
              <span className="recipe-arrow">→</span>
              <div className="recipe-item recipe-item--product">
                <span className="recipe-emoji">⚔️</span>
                <span className="recipe-name">Sword</span>
                <span className="recipe-qty">×1</span>
              </div>
            </div>
            <button
              className="hud-btn hud-btn--danger"
              style={{ width: "100%", flex: "none" }}
              disabled={isPending}
              onClick={craftSword}
            >
              🔥 Craft Sword
            </button>
          </div>
        </section>

        {/* Governance */}
        <section className="panel panel--gov">
          <div className="panel-header">
            <div className="panel-icon">🏛️</div>
            <div>
              <div className="panel-title">Governance</div>
              <div className="panel-desc">delegate · vote</div>
            </div>
          </div>
          <div className="gov-actions">
            <div className="gov-row">
              <div className="gov-row-label">🗳 Voting Power</div>
              <button className="hud-btn hud-btn--rune" disabled={isPending} onClick={delegateVotes}>
                Delegate to Self
              </button>
            </div>
            <div className="gov-row">
              <div className="gov-row-label">📋 Cast Vote</div>
              <input
                className="hud-input"
                value={proposalId}
                onChange={(e) => setProposalId(e.target.value)}
                placeholder="Proposal ID"
              />
              <button
                className="hud-btn hud-btn--rune"
                disabled={isPending || proposalId.length === 0}
                onClick={voteForProp}
              >
                ✔ Vote For
              </button>
            </div>
          </div>
        </section>

      </div>

      {/* Error */}
      {errorMsg && (
        <div className="error-banner">
          <span className="error-icon">⚠</span>
          <span className="error-text">{errorMsg}</span>
        </div>
      )}

      {/* Footer */}
      <footer className="hud-footer">
        <span>ERC-1155</span>
        <span className="footer-dot" />
        <span>Anvil · 31337</span>
        <span className="footer-dot" />
        <span>GameFi Protocol v1</span>
      </footer>
    </main>
  );
}

/* ── Bootstrap ─────────────────────────────────────────────── */
createRoot(document.getElementById("root")!).render(
  <WagmiProvider config={config}>
    <QueryClientProvider client={new QueryClient()}>
      <App />
    </QueryClientProvider>
  </WagmiProvider>
);
