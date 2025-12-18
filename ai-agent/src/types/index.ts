/**
 * Protocol Metrics
 */
export interface ProtocolMetrics {
  protocol: string;
  apy: number; // Annual Percentage Yield in basis points (e.g., 500 = 5%)
  utilization: number; // Utilization rate 0-100%
  liquidity: bigint; // Available liquidity in USDC
  riskScore: number; // Risk score 0-100
  lastUpdated: number; // Timestamp
}

/**
 * Rebalancing Proposal
 */
export interface RebalanceProposal {
  targetAllocation: [number, number, number]; // [ondo%, ethena%, aave%]
  expectedYieldImprovement: number; // Expected yield improvement in basis points
  reasoning: string; // AI reasoning for the proposal
  timestamp: number;
}

/**
 * Decision Memory Entry
 */
export interface DecisionMemoryEntry {
  timestamp: number;
  proposal: RebalanceProposal;
  executed: boolean;
  actualYieldImprovement?: number;
  error?: string;
}

/**
 * Vault State
 */
export interface VaultState {
  totalAssets: bigint;
  totalShares: bigint;
  currentAllocation: [number, number, number];
  sharePrice: bigint;
  lastRebalanceTime: number;
}

/**
 * Market Conditions
 */
export interface MarketConditions {
  ethVolatility: number;
  btcVolatility: number;
  mntVolatility: number;
  ethPrice: bigint;
  btcPrice: bigint;
  mntPrice: bigint;
  timestamp: number;
}

/**
 * Agent Configuration
 */
export interface AgentConfig {
  vaultAddress: string;
  rpcUrl: string;
  rebalanceCheckInterval: number; // milliseconds
  minYieldImprovement: number; // basis points
  maxAllocationChange: number; // percentage points
}
