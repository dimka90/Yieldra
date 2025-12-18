import { DecisionMemoryEntry, RebalanceProposal } from "../types/index.js";

/**
 * DecisionMemory
 * Tracks past rebalancing decisions and outcomes
 */
export class DecisionMemory {
  private decisions: DecisionMemoryEntry[] = [];
  private maxMemorySize = 100; // Keep last 100 decisions

  /**
   * Record a decision
   * @param proposal Rebalance proposal
   * @param executed Whether the proposal was executed
   * @param actualYieldImprovement Actual yield improvement (if executed)
   * @param error Error message (if failed)
   */
  recordDecision(
    proposal: RebalanceProposal,
    executed: boolean,
    actualYieldImprovement?: number,
    error?: string
  ): void {
    const entry: DecisionMemoryEntry = {
      timestamp: Date.now(),
      proposal,
      executed,
      actualYieldImprovement,
      error,
    };

    this.decisions.push(entry);

    // Archive old decisions if memory exceeds max size
    if (this.decisions.length > this.maxMemorySize) {
      this.decisions = this.decisions.slice(-this.maxMemorySize);
    }
  }

  /**
   * Get all decisions
   * @returns Array of decision memory entries
   */
  getAllDecisions(): DecisionMemoryEntry[] {
    return [...this.decisions];
  }

  /**
   * Get recent decisions
   * @param count Number of recent decisions to return
   * @returns Array of recent decision memory entries
   */
  getRecentDecisions(count: number): DecisionMemoryEntry[] {
    return this.decisions.slice(-count);
  }

  /**
   * Get successful decisions
   * @returns Array of successful decision memory entries
   */
  getSuccessfulDecisions(): DecisionMemoryEntry[] {
    return this.decisions.filter((d) => d.executed && !d.error);
  }

  /**
   * Get failed decisions
   * @returns Array of failed decision memory entries
   */
  getFailedDecisions(): DecisionMemoryEntry[] {
    return this.decisions.filter((d) => d.error);
  }

  /**
   * Calculate success rate
   * @returns Success rate as percentage (0-100)
   */
  calculateSuccessRate(): number {
    if (this.decisions.length === 0) return 0;

    const successful = this.decisions.filter((d) => d.executed && !d.error).length;
    return Math.round((successful / this.decisions.length) * 100);
  }

  /**
   * Calculate average yield improvement
   * @returns Average yield improvement in basis points
   */
  calculateAverageYieldImprovement(): number {
    const successful = this.getSuccessfulDecisions();
    if (successful.length === 0) return 0;

    const totalImprovement = successful.reduce((sum, d) => sum + (d.actualYieldImprovement || 0), 0);
    return Math.round(totalImprovement / successful.length);
  }

  /**
   * Get decision statistics
   * @returns Object with decision statistics
   */
  getStatistics(): {
    totalDecisions: number;
    successfulDecisions: number;
    failedDecisions: number;
    successRate: number;
    averageYieldImprovement: number;
  } {
    const successful = this.getSuccessfulDecisions().length;
    const failed = this.getFailedDecisions().length;

    return {
      totalDecisions: this.decisions.length,
      successfulDecisions: successful,
      failedDecisions: failed,
      successRate: this.calculateSuccessRate(),
      averageYieldImprovement: this.calculateAverageYieldImprovement(),
    };
  }

  /**
   * Clear memory
   */
  clear(): void {
    this.decisions = [];
  }

  /**
   * Export memory to JSON
   * @returns JSON string representation of memory
   */
  export(): string {
    return JSON.stringify(this.decisions, null, 2);
  }

  /**
   * Import memory from JSON
   * @param json JSON string representation of memory
   */
  import(json: string): void {
    try {
      this.decisions = JSON.parse(json);
    } catch (error) {
      console.error("Failed to import memory:", error);
    }
  }
}
