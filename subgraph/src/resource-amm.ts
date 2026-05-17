import { BigInt, Bytes } from "@graphprotocol/graph-ts";
import { LiquidityAdded, LiquidityRemoved, Swapped } from "../generated/ResourceAMM/ResourceAMM";
import { LiquidityEvent, Swap } from "../generated/schema";

export function handleSwapped(event: Swapped): void {
  let entity = new Swap(event.transaction.hash.concatI32(event.logIndex.toI32()));
  entity.trader = event.params.trader;
  entity.tokenIn = event.params.tokenIn;
  entity.tokenOut = event.params.tokenOut;
  entity.amountIn = event.params.amountIn;
  entity.amountOut = event.params.amountOut;
  entity.blockNumber = event.block.number;
  entity.timestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;
  entity.save();
}

export function handleLiquidityAdded(event: LiquidityAdded): void {
  saveLiquidity(event.transaction.hash.concatI32(event.logIndex.toI32()), "ADD", event.params.provider, event.params.amountA, event.params.amountB, event.params.liquidity, event.block.number, event.block.timestamp);
}

export function handleLiquidityRemoved(event: LiquidityRemoved): void {
  saveLiquidity(event.transaction.hash.concatI32(event.logIndex.toI32()), "REMOVE", event.params.provider, event.params.amountA, event.params.amountB, event.params.liquidity, event.block.number, event.block.timestamp);
}

function saveLiquidity(id: Bytes, action: string, provider: Bytes, amountA: BigInt, amountB: BigInt, liquidity: BigInt, blockNumber: BigInt, timestamp: BigInt): void {
  let entity = new LiquidityEvent(id);
  entity.provider = provider;
  entity.action = action;
  entity.amountA = amountA;
  entity.amountB = amountB;
  entity.liquidity = liquidity;
  entity.blockNumber = blockNumber;
  entity.timestamp = timestamp;
  entity.save();
}
