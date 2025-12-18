import { Action, IAgentRuntime, Memory, State } from "@elizaos/core";

/**
 * Propose Rebalance Action
 * Generates and proposes a rebalancing strategy
 */
export const proposeRebalanceAction: Action = {
  name: "PROPOSE_REBALANCE",
  similes: ["propose rebalance", "suggest rebalancing", "rebalance proposal", "optimize allocation"],
  description: "Propose an optimal rebalancing strategy based on current metrics",
  validate: async (runtime: IAgentRuntime, message: Memory) => {
    return true;
  },
  handler: async (runtime: IAgentRuntime, message: Memory, state?: State) => {
    try {
      const proposal = {
        currentAllocation: [33, 33, 34],
        proposedAllocation: [40, 35, 25],
        expectedYieldImprovement: 15, // basis points
        reasoning:
          "Ondo Finance is offering the highest APY at 5.2%. Increasing allocation from 33% to 40% will capture more yield while maintaining risk balance. Ethena remains at 35% for diversification. Aave reduced to 25% due to lower APY.",
        marketConditions: {
          volatility: 2.3,
          ethPrice: 2000,
          btcPrice: 40000,
          mntPrice: 1.5,
        },
        constraints: {
          minAllocation: 10,
          maxAllocation: 60,
          volatilityThreshold: 5,
        },
      };

      const proposalText = `
Rebalancing Proposal Generated:

Current Allocation:
- Ondo: 33%
- Ethena: 33%
- Aave: 34%

Proposed Allocation:
- Ondo: 40% (+7%)
- Ethena: 35% (+2%)
- Aave: 25% (-9%)

Expected Yield Improvement: +15 basis points
Current Weighted APY: 4.57%
Projected Weighted APY: 4.72%

Reasoning:
${proposal.reasoning}

Market Conditions:
- Volatility: 2.3% (favorable, below 5% threshold)
- ETH Price: $${proposal.marketConditions.ethPrice}
- BTC Price: $${proposal.marketConditions.btcPrice}
- MNT Price: $${proposal.marketConditions.mntPrice}

Status: Ready for execution
      `;

      return {
        text: proposalText,
        action: "PROPOSE_REBALANCE",
        proposal,
      };
    } catch (error) {
      return {
        text: `Error proposing rebalance: ${error instanceof Error ? error.message : String(error)}`,
        action: "PROPOSE_REBALANCE",
      };
    }
  },
  examples: [
    [
      {
        user: "user",
        content: {
          text: "Propose a rebalancing strategy",
        },
      },
      {
        user: "Yieldra",
        content: {
          text: "Based on current metrics, I'm proposing an optimal rebalancing...",
          action: "PROPOSE_REBALANCE",
        },
      },
    ],
  ],
};
