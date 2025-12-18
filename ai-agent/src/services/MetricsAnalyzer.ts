import { ProtocolMetrics, MarketConditions } from "../types/index.js";

/**
 * MetricsAnalyzer
 * Analyzes protocol metrics and market conditions to identify rebalancing opportunities
 */
export class MetricsAnalyzer {
  private protocolMetrics: Map<string, ProtocolMetrics> = new Map();
  private marketConditions: MarketConditions | null = null;

  /**
   * Update protocol metrics
   * @param protocol Protocol name
   * @param metrics Protocol metrics
   */
  updateProtocolMetrics(protocol: string, metrics: ProtocolMetrics): void {
    this.protocolMetrics.set(protocol, metrics);
  }

  /**
   * Update market conditions
   * @param conditions Market conditions
   */
  updateMarketConditions(conditions: MarketConditions): void {
    this.marketConditions = conditions;
  }

  /**
   * Get all protocol metrics
   * @returns Map of protocol metrics
   */
  getProtocolMetrics(): Map<string, ProtocolMetrics> {
    return this.protocolMetrics;
  }

  /**
   * Get market conditions
   * @returns Market conditions
   */
  getMarketConditions(): MarketConditions | null {
    return this.marketConditions;
  }

  /**
   * Calculate average APY across protocols
   * @returns Average APY in basis points
   */
  calculateAverageAPY(): number {
    if (this.protocolMetrics.size === 0) return 0;

    let totalAPY = 0;
    this.protocolMetrics.forEach((metrics) => {
      totalAPY += metrics.apy;
    });

    return Math.round(totalAPY / this.protocolMetrics.size);
  }

  /**
   * Calculate weighted APY based on allocation
   * @param allocation Current allocation [ondo%, ethena%, aave%]
   * @returns Weighted APY in basis points
   */
  calculateWeightedAPY(allocation: [number, number, number]): number {
    const protocols = ["ondo", "ethena", "aave"];
    let weightedAPY = 0;

    for (let i = 0; i < 3; i++) {
      const metrics = this.protocolMetrics.get(protocols[i]);
      if (metrics) {
        weightedAPY += (metrics.apy * allocation[i]) / 100;
      }
    }

    return Math.round(weightedAPY);
  }

  /**
   * Identify rebalancing opportunity
   * @param currentAllocation Current allocation
   * @returns True if rebalancing would improve yield
   */
  identifyRebalancingOpportunity(currentAllocation: [number, number, number]): boolean {
    const currentWeightedAPY = this.calculateWeightedAPY(currentAllocation);
    const optimalAllocation = this.calculateOptimalAllocation();
    const optimalWeightedAPY = this.calculateWeightedAPY(optimalAllocation);

    // Rebalance if improvement is significant (> 10 basis points)
    return optimalWeightedAPY - currentWeightedAPY > 10;
  }

  /**
   * Calculate optimal allocation based on APYs
   * @returns Optimal allocation [ondo%, ethena%, aave%]
   */
  calculateOptimalAllocation(): [number, number, number] {
    const protocols = ["ondo", "ethena", "aave"];
    const apys: number[] = [];

    for (const protocol of protocols) {
      const metrics = this.protocolMetrics.get(protocol);
      apys.push(metrics?.apy || 0);
    }

    // Calculate allocation based on APY (higher APY = higher allocation)
    const totalAPY = apys.reduce((a, b) => a + b, 0);
    if (totalAPY === 0) {
      return [33, 33, 34]; // Default equal allocation
    }

    const allocation: [number, number, number] = [
      Math.round((apys[0] / totalAPY) * 100),
      Math.round((apys[1] / totalAPY) * 100),
      0,
    ];

    // Ensure third element sums to 100
    allocation[2] = 100 - allocation[0] - allocation[1];

    // Enforce min/max constraints (10%-60%)
    for (let i = 0; i < 3; i++) {
      if (allocation[i] < 10) allocation[i] = 10;
      if (allocation[i] > 60) allocation[i] = 60;
    }

    // Rebalance to sum to 100
    const sum = allocation[0] + allocation[1] + allocation[2];
    if (sum !== 100) {
      const diff = 100 - sum;
      allocation[2] += diff;
    }

    return allocation;
  }

  /**
   * Calculate expected yield improvement
   * @param currentAllocation Current allocation
   * @param newAllocation New allocation
   * @returns Expected yield improvement in basis points
   */
  calculateYieldImprovement(
    currentAllocation: [number, number, number],
    newAllocation: [number, number, number]
  ): number {
    const currentWeightedAPY = this.calculateWeightedAPY(currentAllocation);
    const newWeightedAPY = this.calculateWeightedAPY(newAllocation);

    return newWeightedAPY - currentWeightedAPY;
  }

  /**
   * Evaluate risk score for allocation
   * @param allocation Allocation to evaluate
   * @returns Risk score 0-100
   */
  evaluateRiskScore(allocation: [number, number, number]): number {
    const protocols = ["ondo", "ethena", "aave"];
    let weightedRisk = 0;

    for (let i = 0; i < 3; i++) {
      const metrics = this.protocolMetrics.get(protocols[i]);
      if (metrics) {
        weightedRisk += (metrics.riskScore * allocation[i]) / 100;
      }
    }

    return Math.round(weightedRisk);
  }

  /**
   * Check if market conditions are favorable for rebalancing
   * @returns True if market conditions are favorable
   */
  areMarketConditionsFavorable(): boolean {
    if (!this.marketConditions) return false;

    // Market is favorable if volatility is low (< 5%)
    const maxVolatility = Math.max(
      this.marketConditions.ethVolatility,
      this.marketConditions.btcVolatility,
      this.marketConditions.mntVolatility
    );

    return maxVolatility < 500; // 500 basis points = 5%
  }

  /**
   * Generate reasoning for rebalancing proposal
   * @param currentAllocation Current allocation
   * @param newAllocation New allocation
   * @returns Reasoning string
   */
  generateReasoning(
    currentAllocation: [number, number, number],
    newAllocation: [number, number, number]
  ): string {
    const protocols = ["Ondo", "Ethena", "Aave"];
    const changes: string[] = [];

    for (let i = 0; i < 3; i++) {
      const change = newAllocation[i] - currentAllocation[i];
      if (change > 0) {
        changes.push(`increase ${protocols[i]} by ${change}%`);
      } else if (change < 0) {
        changes.push(`decrease ${protocols[i]} by ${-change}%`);
      }
    }

    const yieldImprovement = this.calculateYieldImprovement(currentAllocation, newAllocation);
    const riskScore = this.evaluateRiskScore(newAllocation);

    return (
      `Rebalancing proposal: ${changes.join(", ")}. ` +
      `Expected yield improvement: ${(yieldImprovement / 100).toFixed(2)}%. ` +
      `Risk score: ${riskScore}/100.`
    );
  }
}
