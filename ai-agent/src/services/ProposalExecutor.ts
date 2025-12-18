import { Contract, JsonRpcProvider } from "ethers";
import { RebalanceProposal, VaultState } from "../types/index.js";
import { DecisionMemory } from "./DecisionMemory.js";

/**
 * ProposalExecutor
 * Executes rebalancing proposals on the vault contract
 */
export class ProposalExecutor {
  private provider: JsonRpcProvider;
  private vaultContract: Contract;
  private decisionMemory: DecisionMemory;
  private maxRetries = 3;

  constructor(provider: JsonRpcProvider, vaultContract: Contract, decisionMemory: DecisionMemory) {
    this.provider = provider;
    this.vaultContract = vaultContract;
    this.decisionMemory = decisionMemory;
  }

  /**
   * Execute rebalance proposal
   * @param proposal Rebalance proposal
   * @returns True if execution was successful
   */
  async executeProposal(proposal: RebalanceProposal): Promise<boolean> {
    let lastError: Error | null = null;

    for (let attempt = 1; attempt <= this.maxRetries; attempt++) {
      try {
        console.log(`Executing proposal (attempt ${attempt}/${this.maxRetries})...`);

        // Call vault rebalance function
        const tx = await this.vaultContract.rebalance(proposal.targetAllocation);

        // Wait for transaction confirmation
        const receipt = await tx.wait();

        if (receipt && receipt.status === 1) {
          console.log(`Proposal executed successfully: ${receipt.transactionHash}`);

          // Record successful execution
          this.decisionMemory.recordDecision(proposal, true);

          return true;
        } else {
          throw new Error("Transaction failed");
        }
      } catch (error) {
        lastError = error instanceof Error ? error : new Error(String(error));
        console.error(`Execution attempt ${attempt} failed:`, lastError.message);

        // Wait before retrying
        if (attempt < this.maxRetries) {
          await this.delay(1000 * attempt); // Exponential backoff
        }
      }
    }

    // Record failed execution
    this.decisionMemory.recordDecision(proposal, false, undefined, lastError?.message);

    return false;
  }

  /**
   * Monitor proposal execution
   * @param proposal Rebalance proposal
   * @param maxWaitTime Maximum time to wait for execution (ms)
   * @returns True if proposal was executed within time limit
   */
  async monitorProposalExecution(proposal: RebalanceProposal, maxWaitTime: number = 300000): Promise<boolean> {
    const startTime = Date.now();

    while (Date.now() - startTime < maxWaitTime) {
      try {
        // Check current vault state
        const currentAllocation = await this.vaultContract.currentAllocation();

        // Check if allocation matches proposal
        if (this.allocationMatches(currentAllocation, proposal.targetAllocation)) {
          console.log("Proposal execution confirmed");
          return true;
        }

        // Wait before checking again
        await this.delay(5000); // Check every 5 seconds
      } catch (error) {
        console.error("Error monitoring proposal:", error);
      }
    }

    console.log("Proposal execution monitoring timed out");
    return false;
  }

  /**
   * Get current vault state
   * @returns Current vault state
   */
  async getVaultState(): Promise<VaultState> {
    try {
      const [totalAssets, totalShares, currentAllocation, lastRebalanceTime] = await Promise.all([
        this.vaultContract.getTotalAssets(),
        this.vaultContract.totalShares(),
        this.vaultContract.currentAllocation(),
        this.vaultContract.lastRebalanceTime(),
      ]);

      const sharePrice = totalShares > 0n ? (totalAssets * 10n ** 18n) / totalShares : 10n ** 18n;

      return {
        totalAssets,
        totalShares,
        currentAllocation: [Number(currentAllocation[0]), Number(currentAllocation[1]), Number(currentAllocation[2])],
        sharePrice,
        lastRebalanceTime: Number(lastRebalanceTime),
      };
    } catch (error) {
      console.error("Error getting vault state:", error);
      throw error;
    }
  }

  /**
   * Check if allocation matches target
   * @param current Current allocation
   * @param target Target allocation
   * @returns True if allocations match within tolerance
   */
  private allocationMatches(current: any[], target: [number, number, number]): boolean {
    const tolerance = 1; // 1% tolerance

    for (let i = 0; i < 3; i++) {
      const diff = Math.abs(Number(current[i]) - target[i]);
      if (diff > tolerance) {
        return false;
      }
    }

    return true;
  }

  /**
   * Delay execution
   * @param ms Milliseconds to delay
   */
  private delay(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  /**
   * Get decision memory
   * @returns Decision memory instance
   */
  getDecisionMemory(): DecisionMemory {
    return this.decisionMemory;
  }
}
