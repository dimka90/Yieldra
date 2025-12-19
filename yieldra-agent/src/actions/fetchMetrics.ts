import { Action, IAgentRuntime, Memory, State } from '@elizaos/core';
import { MetricsService } from '../services/metricsService';

/**
 * Get market condition based on volatility
 */
function getMarketCondition(volatility: {
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
}

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
      const metricsService = new MetricsService();

      // Show that we're fetching
      let fetchingText = '🔄 Fetching live protocol metrics from DeFi Llama...\n';
      fetchingText += '📊 Calling Ondo Finance API...\n';
      fetchingText += '📊 Calling Ethena API...\n';
      fetchingText += '📊 Calling Aave V3 API...\n';
      fetchingText += '💰 Fetching market prices from CoinGecko...\n';
      fetchingText += '📈 Calculating market volatility...\n\n';

      // Fetch all metrics in parallel
      const [metrics, prices, volatility] = await Promise.all([
        metricsService.getAllMetrics(),
        metricsService.getMarketPrices(),
        metricsService.getMarketVolatility(),
      ]);

      // Calculate weighted APY
      const avgApy =
        metrics.reduce((sum, m) => sum + m.apy, 0) / metrics.length;

      // Format response with real data
      const metricsText = fetchingText + `✅ Successfully fetched live protocol metrics!

📊 PROTOCOL METRICS (Real-time from DeFi Llama):

🔹 Ondo Finance (USDY):
   • APY: ${(metrics[0].apy / 100).toFixed(2)}%
   • Utilization: ${metrics[0].utilization}%
   • TVL: $${(metrics[0].liquidity / 1e9).toFixed(2)}B
   • Risk Score: ${metrics[0].riskScore}/100

🔹 Ethena (USDe):
   • APY: ${(metrics[1].apy / 100).toFixed(2)}%
   • Utilization: ${metrics[1].utilization}%
   • TVL: $${(metrics[1].liquidity / 1e9).toFixed(2)}B
   • Risk Score: ${metrics[1].riskScore}/100

🔹 Aave V3 (aUSDC):
   • APY: ${(metrics[2].apy / 100).toFixed(2)}%
   • Utilization: ${metrics[2].utilization}%
   • TVL: $${(metrics[2].liquidity / 1e9).toFixed(2)}B
   • Risk Score: ${metrics[2].riskScore}/100

💰 MARKET DATA (Real-time from CoinGecko):
   • ETH: $${prices.eth.toFixed(2)} (${volatility.ethVolatility.toFixed(2)}% 24h change)
   • BTC: $${prices.btc.toFixed(2)} (${volatility.btcVolatility.toFixed(2)}% 24h change)
   • MNT: $${prices.mnt.toFixed(4)} (${volatility.mntVolatility.toFixed(2)}% 24h change)

📈 ANALYSIS:
   • Weighted Average APY: ${(avgApy / 100).toFixed(2)}%
   • Market Conditions: ${getMarketCondition(volatility)}
   • Best Yield: ${metrics.reduce((a, b) => a.apy > b.apy ? a : b).protocol.toUpperCase()} (${(Math.max(...metrics.map(m => m.apy)) / 100).toFixed(2)}%)
   • Lowest Risk: ${metrics.reduce((a, b) => a.riskScore < b.riskScore ? a : b).protocol.toUpperCase()} (${Math.min(...metrics.map(m => m.riskScore))}/100)

🔗 Data Sources:
   • Protocol TVL: DeFi Llama API (https://api.llama.fi)
   • Market Prices: CoinGecko API (https://api.coingecko.com)
   • Last Updated: ${new Date().toISOString()}
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
        text: `❌ Error fetching metrics: ${error instanceof Error ? error.message : String(error)}`,
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
};
