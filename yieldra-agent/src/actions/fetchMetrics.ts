import { Action, IAgentRuntime, Memory, State } from '@elizaos/core';
import { MetricsService } from '../services/metricsService';

/**
 * Fetch Real Protocol Metrics Action
 * Fetches actual metrics from DeFi Llama and Coingecko
 */
export const fetchMetricsAction: Action = {
  name: 'FETCH_METRICS',
  similes: [
    'fetch metrics',
    'get protocol data',
    'check yields',
    'analyze protocols',
    'market analysis',
  ],
  description:
    'Fetch real protocol metrics from DeFi Llama and market data from Coingecko',
  validate: async (runtime: IAgentRuntime, message: Memory) => {
    return true;
  },
  handler: async (runtime: IAgentRuntime, message: Memory, state?: State) => {
    try {
      const rpcUrl = process.env.MANTLE_RPC_URL || 'https://rpc.mantle.xyz';
      const metricsService = new MetricsService(rpcUrl);

      // Fetch all metrics in parallel
      const [metrics, prices, volatility] = await Promise.all([
        metricsService.getAllMetrics(),
        metricsService.getMarketPrices(),
        metricsService.getMarketVolatility(),
      ]);

      // Calculate weighted APY
      const avgApy =
        metrics.reduce((sum, m) => sum + m.apy, 0) / metrics.length;

      // Format response
      const metricsText = `
Real Protocol Metrics (Live Data):

Ondo Finance (USDY):
  APY: ${(metrics[0].apy / 100).toFixed(2)}%
  Utilization: ${metrics[0].utilization}%
  Risk Score: ${metrics[0].riskScore}/100

Ethena (USDe):
  APY: ${(metrics[1].apy / 100).toFixed(2)}%
  Utilization: ${metrics[1].utilization}%
  Risk Score: ${metrics[1].riskScore}/100

Aave V3 (aUSDC):
  APY: ${(metrics[2].apy / 100).toFixed(2)}%
  Utilization: ${metrics[2].utilization}%
  Risk Score: ${metrics[2].riskScore}/100

Market Data:
  ETH Price: $${prices.eth.toFixed(2)}
  BTC Price: $${prices.btc.toFixed(2)}
  MNT Price: $${prices.mnt.toFixed(4)}

Market Volatility (24h):
  ETH: ${(volatility.ethVolatility / 100).toFixed(2)}%
  BTC: ${(volatility.btcVolatility / 100).toFixed(2)}%
  MNT: ${(volatility.mntVolatility / 100).toFixed(2)}%

Average Weighted APY: ${(avgApy / 100).toFixed(2)}%
Market Conditions: ${this.getMarketCondition(volatility)}

Data Source: DeFi Llama + Coingecko (Real-time)
Last Updated: ${new Date().toISOString()}
      `;

      return {
        text: metricsText,
        action: 'FETCH_METRICS',
        metrics,
        prices,
        volatility,
      };
    } catch (error) {
      return {
        text: `Error fetching metrics: ${error instanceof Error ? error.message : String(error)}`,
        action: 'FETCH_METRICS',
      };
    }
  },

  examples: [
    [
      {
        user: 'user',
        content: {
          text: 'Fetch the latest protocol metrics',
        },
      },
      {
        user: 'Yieldra',
        content: {
          text: 'I am fetching real-time protocol metrics from DeFi Llama and market data from Coingecko...',
          action: 'FETCH_METRICS',
        },
      },
    ],
  ],

  getMarketCondition(volatility: {
    ethVolatility: number;
    btcVolatility: number;
    mntVolatility: number;
  }): string {
    const maxVolatility = Math.max(
      volatility.ethVolatility,
      volatility.btcVolatility,
      volatility.mntVolatility
    );

    if (maxVolatility < 200) return '✓ Favorable (Low volatility)';
    if (maxVolatility < 500) return '⚠ Moderate (Medium volatility)';
    return '✗ Unfavorable (High volatility)';
  },
};
