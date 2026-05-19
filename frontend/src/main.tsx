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

const anvil = defineChain({
  id: 31337,
  name: "Anvil Local",
  nativeCurrency: {
    name: "Ether",
    symbol: "ETH",
    decimals: 18
  },
  rpcUrls: {
    default: {
      http: ["http://127.0.0.1:8545"]
    }
  }
});

const config = createConfig({
  chains: [anvil],
  connectors: [injected()],
  transports: {
    [anvil.id]: http("http://127.0.0.1:8545")
  }
});

function contractAddress(name: string): `0x${string}` {
  const value = import.meta.env[name];

  if (!value || !/^0x[a-fA-F0-9]{40}$/.test(value)) {
    throw new Error(`${name} is missing in .env`);
  }

  return value as `0x${string}`;
}

const addresses = {
  gameToken: contractAddress("VITE_GAME_TOKEN"),
  gameItems: contractAddress("VITE_GAME_ITEMS"),
  amm: contractAddress("VITE_RESOURCE_AMM"),
  governor: contractAddress("VITE_GOVERNOR")
};

const erc20Abi = [
  {
    type: "function",
    name: "balanceOf",
    stateMutability: "view",
    inputs: [{ name: "account", type: "address" }],
    outputs: [{ type: "uint256" }]
  },
  {
    type: "function",
    name: "approve",
    stateMutability: "nonpayable",
    inputs: [
      { name: "spender", type: "address" },
      { name: "amount", type: "uint256" }
    ],
    outputs: [{ type: "bool" }]
  },
  {
    type: "function",
    name: "delegate",
    stateMutability: "nonpayable",
    inputs: [{ name: "delegatee", type: "address" }],
    outputs: []
  }
] as const;

const itemsAbi = [
  {
    type: "function",
    name: "balanceOf",
    stateMutability: "view",
    inputs: [
      { name: "account", type: "address" },
      { name: "id", type: "uint256" }
    ],
    outputs: [{ type: "uint256" }]
  },
  {
    type: "function",
    name: "craftSword",
    stateMutability: "nonpayable",
    inputs: [],
    outputs: []
  }
] as const;

const ammAbi = [
  {
    type: "function",
    name: "reserveA",
    stateMutability: "view",
    inputs: [],
    outputs: [{ type: "uint256" }]
  },
  {
    type: "function",
    name: "reserveB",
    stateMutability: "view",
    inputs: [],
    outputs: [{ type: "uint256" }]
  },
  {
    type: "function",
    name: "swapAForB",
    stateMutability: "nonpayable",
    inputs: [
      { name: "amountIn", type: "uint256" },
      { name: "minAmountOut", type: "uint256" }
    ],
    outputs: [{ type: "uint256" }]
  }
] as const;

const governorAbi = [
  {
    type: "function",
    name: "castVote",
    stateMutability: "nonpayable",
    inputs: [
      { name: "proposalId", type: "uint256" },
      { name: "support", type: "uint8" }
    ],
    outputs: [{ type: "uint256" }]
  }
] as const;

function App() {
  const { address, chain } = useAccount();

  const { connect, connectors } = useConnect();

  const { switchChain, chains } = useSwitchChain();

  const { writeContractAsync, error, isPending } = useWriteContract();

  const [swapAmount, setSwapAmount] = useState("1");

  const [proposalId, setProposalId] = useState("");

  const nativeBalance = useBalance({
    address
  });

  const gameBalance = useReadContract({
    address: addresses.gameToken,
    abi: erc20Abi,
    functionName: "balanceOf",
    args: address ? [address] : undefined,
    query: {
      enabled: Boolean(address)
    }
  });

  const woodBalance = useReadContract({
    address: addresses.gameItems,
    abi: itemsAbi,
    functionName: "balanceOf",
    args: address ? [address, 1n] : undefined,
    query: {
      enabled: Boolean(address)
    }
  });

  const ironBalance = useReadContract({
    address: addresses.gameItems,
    abi: itemsAbi,
    functionName: "balanceOf",
    args: address ? [address, 2n] : undefined,
    query: {
      enabled: Boolean(address)
    }
  });

  const swordBalance = useReadContract({
    address: addresses.gameItems,
    abi: itemsAbi,
    functionName: "balanceOf",
    args: address ? [address, 3n] : undefined,
    query: {
      enabled: Boolean(address)
    }
  });

  const reserveA = useReadContract({
    address: addresses.amm,
    abi: ammAbi,
    functionName: "reserveA"
  });

  const reserveB = useReadContract({
    address: addresses.amm,
    abi: ammAbi,
    functionName: "reserveB"
  });

  const status = useMemo(() => {
    return error?.message ?? "";
  }, [error]);

  async function approveAmm() {
    await writeContractAsync({
      address: addresses.gameToken,
      abi: erc20Abi,
      functionName: "approve",
      args: [addresses.amm, parseEther("1000000")]
    });
  }

  async function swapAForB() {
    await writeContractAsync({
      address: addresses.amm,
      abi: ammAbi,
      functionName: "swapAForB",
      args: [parseEther(swapAmount), 0n]
    });
  }

  async function craftSword() {
    await writeContractAsync({
      address: addresses.gameItems,
      abi: itemsAbi,
      functionName: "craftSword"
    });
  }

  async function delegateVotes() {
    if (!address) return;

    await writeContractAsync({
      address: addresses.gameToken,
      abi: erc20Abi,
      functionName: "delegate",
      args: [address]
    });
  }

  async function voteForProposal() {
    if (!proposalId) return;

    await writeContractAsync({
      address: addresses.governor,
      abi: governorAbi,
      functionName: "castVote",
      args: [BigInt(proposalId), 1]
    });
  }

  return (
    <main>
      <header>
        <h1>GameFi Economy</h1>

        {address ? (
          <span>
            {address.slice(0, 6)}...
            {address.slice(-4)} on {chain?.name}
          </span>
        ) : (
          <button
            onClick={() =>
              connect({
                connector: connectors[0]
              })
            }
          >
            Connect Wallet
          </button>
        )}
      </header>

      <section className="toolbar">
        {chains.map((target) => (
          <button
            key={target.id}
            onClick={() =>
              switchChain({
                chainId: target.id
              })
            }
          >
            {target.name}
          </button>
        ))}
      </section>

      <section className="grid">
        <article>
          <h2>Balances</h2>

          <p>
            Native:{" "}
            {nativeBalance.data
              ? formatEther(nativeBalance.data.value)
              : "0"}
          </p>

          <p>
            GTK:{" "}
            {gameBalance.data
              ? formatEther(gameBalance.data)
              : "0"}
          </p>

          <p>Wood: {woodBalance.data?.toString() ?? "0"}</p>

          <p>Iron: {ironBalance.data?.toString() ?? "0"}</p>

          <p>Sword: {swordBalance.data?.toString() ?? "0"}</p>
        </article>

        <article>
          <h2>AMM</h2>

          <p>
            Reserve A:{" "}
            {reserveA.data
              ? formatEther(reserveA.data)
              : "0"}
          </p>

          <p>
            Reserve B:{" "}
            {reserveB.data
              ? formatEther(reserveB.data)
              : "0"}
          </p>

          <input
            value={swapAmount}
            onChange={(e) => setSwapAmount(e.target.value)}
          />

          <button
            disabled={isPending}
            onClick={approveAmm}
          >
            Approve
          </button>

          <button
            disabled={isPending}
            onClick={swapAForB}
          >
            Swap A to B
          </button>
        </article>

        <article>
          <h2>Crafting</h2>

          <button
            disabled={isPending}
            onClick={craftSword}
          >
            Craft Sword
          </button>
        </article>

        <article>
          <h2>Governance</h2>

          <button
            disabled={isPending}
            onClick={delegateVotes}
          >
            Delegate
          </button>

          <input
            value={proposalId}
            onChange={(e) => setProposalId(e.target.value)}
            placeholder="Proposal ID"
          />

          <button
            disabled={isPending || proposalId.length === 0}
            onClick={voteForProposal}
          >
            Vote For
          </button>
        </article>
      </section>

      {status && (
        <p className="error">
          {status}
        </p>
      )}
    </main>
  );
}

createRoot(document.getElementById("root")!).render(
  <WagmiProvider config={config}>
    <QueryClientProvider client={new QueryClient()}>
      <App />
    </QueryClientProvider>
  </WagmiProvider>
);