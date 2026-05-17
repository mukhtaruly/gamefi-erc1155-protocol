import { VoteCast } from "../generated/GameGovernor/GameGovernor";
import { ProposalVote } from "../generated/schema";

export function handleVoteCast(event: VoteCast): void {
  let entity = new ProposalVote(event.transaction.hash.concatI32(event.logIndex.toI32()));
  entity.voter = event.params.voter;
  entity.proposalId = event.params.proposalId;
  entity.support = event.params.support;
  entity.weight = event.params.weight;
  entity.reason = event.params.reason;
  entity.blockNumber = event.block.number;
  entity.timestamp = event.block.timestamp;
  entity.save();
}
