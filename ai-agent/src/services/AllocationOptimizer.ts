import { RebalanceProposal } from "../types/index.js";
import { MetricsAnalyzer } from "./MetricsAnalyzer.js";

/**
 * AllocationOptimizer
 * Generates optimal allocation proposals based on protocol metrics
 */
export class AllocationOptimizer {
  private metricsAnalyzer: MetricsAnalyzer;
  private minAllocation = 10; // 10%
  private maxAllocation = 60; // 60%

  constructor(metricsAnalyzer: MetricsAnalyzer) {
    this.metricsAnalyzer = metricsAnalyzer;
  }

  /**
   * Generate rebalance proposal
   * @param currentAllocation Current allocation
   * @returns Rebalance proposal or null if no improvement
   */
  generateProposal(currentAllocation: [number, number, number]): RebalanceProposal | null {
    // Check if rebalancing opportunity exists
    if (!this.metricsAnalyzer.identifyRebalancingOpportunity(currentAllocation)) {
      return null;
    }

    // Check market conditions
    if (!this.metricsAnalyzer.areMarketConditionsFavorable()) {
      return null;
    }

    // Calculate optimal allocation
    const optimalAllocation = this.metricsAnalyzer.calculateOptimalAllocation();

    // Validate allocation
    if (!this.validateAllocation(optimalAllocation)) {
      return null;
    }

    // Calculate expected yield improvement
    const expectedYieldImprovement = this.metricsAnalyzer.calculateYieldImprovement(
      currentAllocation,
      optimalAllocation
    );

    // Generate reasoning
    const reasoning = this.metricsAnalyzer.generateReasoning(currentAllocation, optimalAllocation);

    return {
      targetAllocation: optimalAllocation,
      expectedYieldImprovement,
      reasoning,
      timestamp: Date.now(),
    };
  }

  /**
   * Validate allocation constraints
   * @param allocation Allocation to validate
   * @returns True if allocation is valid
   */
  private validateAllocation(allocation: [number, number, number]): boolean {
    // Check sum is 100
    const sum = allocation[0] + allocation[1] + allocation[2];
    if (sum !== 100) {
      return false;
    }

    // Check min/max constraints
    for (let i = 0; i < 3; i++) {
      if (allocation[i] < this.minAllocation || allocation[i] > this.maxAllocation) {
        return false;
      }
    }

    return true;
  }

  /**
   * Estimate expected yield improvement
   * @param currentAllocation Current allocation
   * @returns Expected yield improvement in basis points
   */
  estimateYieldImprovement(currentAllocation: [number, number, number]): number {
    const optimalAllocation = this.metricsAnalyzer.calculateOptimalAllocation();
    return this.metricsAnalyzer.calculateYieldImprovement(currentAllocation, optimalAllocation);
  }

  /**
   * Get allocation constraints
   * @returns Object with min and max allocation
   */
  getConstraints(): { min: number; max: number } {
    return {
      min: this.minAllocation,
      max: this.maxAllocation,
    };
  }
}
