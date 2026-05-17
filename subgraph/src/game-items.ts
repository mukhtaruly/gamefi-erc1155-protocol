import { Crafted } from "../generated/GameItems/GameItems";
import { CraftedItem } from "../generated/schema";

export function handleCrafted(event: Crafted): void {
  let entity = new CraftedItem(event.transaction.hash.concatI32(event.logIndex.toI32()));
  entity.player = event.params.player;
  entity.itemId = event.params.itemId;
  entity.amount = event.params.amount;
  entity.blockNumber = event.block.number;
  entity.timestamp = event.block.timestamp;
  entity.save();
}
