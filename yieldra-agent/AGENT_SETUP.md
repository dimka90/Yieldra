# Yieldra Agent Setup & Testing Guide

## Overview
Yieldra is an AI-powered yield optimization agent for the Mantle Network. It analyzes protocol metrics, identifies rebalancing opportunities, and proposes optimal fund allocations.

## Prerequisites

### Required
- Node.js 18+ or Bun
- npm or bun package manager
- Environment variables configured

### Optional (for full functionality)
- Discord bot token (for Discord integration)
- Twitter API credentials (for Twitter integration)
- Telegram bot token (for Telegram integration)

## Environment Setup

1. **Copy environment template:**
   ```bash
   cp .env.example .env
   ```

2. **Configure required variables:**
   ```env
   # LLM Provider (choose one)
   OPENAI_API_KEY=your_key_here
   # OR
   ANTHROPIC_API_KEY=your_key_here
   # OR
   OPENROUTER_API_KEY=your_key_here

   # Optional: Mantle RPC
   MANTLE_RPC_URL=https://rpc.mantle.xyz

   # Optional: Platform integrations
   DISCORD_API_TOKEN=your_token
   TWITTER_API_KEY=your_key
   TELEGRAM_BOT_TOKEN=your_token
   ```

## Installation

### Using npm
```bash
npm install
npm run build
```

### Using bun
```bash
bun install
bun run build.ts
```

## Testing

### 1. Test Metrics Service (Standalone)
```bash
node test-metrics-new.js
```
This verifies that real protocol metrics are being fetched correctly.

### 2. Test Agent Integration
```bash
npm run build
node test-agent-integration.js
```
This tests that the fetchMetricsAction is properly integrated with the agent.

### 3. Type Check
```bash
npm run type-check
```

### 4. Format Check
```bash
npm run format:check
```

## Running the Agent

### Development Mode
```bash
npm run dev
```
This starts the agent in development mode with hot reload.

### Production Mode
```bash
npm start
```
This starts the agent in production mode.

### With Docker
```bash
docker build -t yieldra-agent .
docker run -e OPENAI_API_KEY=your_key yieldra-agent
```

## Agent Capabilities

### Fetch Metrics
The agent can fetch real-time protocol metrics:

**Trigger phrases:**
- "Fetch metrics"
- "Get protocol data"
- "Check yields"
- "Analyze protocols"
- "Market analysis"

**Response includes:**
- Ondo Finance (USDY) metrics
- Ethena (USDe) metrics
- Aave V3 (aUSDC) metrics
- Market prices (ETH, BTC, MNT)
- Market volatility (24h)
- Weighted APY calculation
- Market condition assessment

### Example Interaction
```
User: "Fetch the latest protocol metrics"

Yieldra: "I am fetching real-time protocol metrics from DeFi Llama and market data from Coingecko...

Real Protocol Metrics (Live Data):

Ondo Finance (USDY):
  APY: 5.20%
  Utilization: 85%
  Risk Score: 20/100

Ethena (USDe):
  APY: 8.50%
  Utilization: 85%
  Risk Score: 30/100

Aave V3 (aUSDC):
  APY: 3.50%
  Utilization: 85%
  Risk Score: 15/100

Market Data:
  ETH Price: $2,913.72
  BTC Price: $86,727
  MNT Price: $1.14

Market Volatility (24h):
  ETH: 3.15%
  BTC: 0.26%
  MNT: 3.41%

Average Weighted APY: 5.73%
Market Conditions: ✓ Favorable (Low volatility)

Data Source: DeFi Llama + Coingecko (Real-time)
Last Updated: 2025-12-19T10:30:45.123Z"
```

## Architecture

### Components

1. **MetricsService** (`src/services/metricsService.ts`)
   - Fetches protocol metrics from DeFi Llama
   - Gets market prices from Coingecko
   - Handles multiple TVL data formats
   - Provides graceful fallbacks

2. **fetchMetricsAction** (`src/actions/fetchMetrics.ts`)
   - ElizaOS action for fetching metrics
   - Integrates with agent runtime
   - Formats data for AI reasoning

3. **Character** (`src/character.ts`)
   - Defines Yieldra agent personality
   - Registers actions
   - Configures plugins

## Data Sources

- **Protocol Metrics:** DeFi Llama API
- **Market Prices:** Coingecko API
- **Market Volatility:** Coingecko API

All data is fetched in real-time and used for AI reasoning only (not on-chain execution).

## Troubleshooting

### Agent won't start
1. Check environment variables are set
2. Verify LLM provider credentials
3. Check Node.js version: `node --version`

### Metrics not fetching
1. Check internet connection
2. Verify APIs are accessible:
   - `curl https://api.llama.fi/protocol/aave`
   - `curl https://api.coingecko.com/api/v3/simple/price?ids=ethereum`

### Build errors
1. Clear cache: `rm -rf dist node_modules`
2. Reinstall: `npm install`
3. Rebuild: `npm run build`

## Next Steps

1. ✅ Metrics service working
2. ✅ Agent integration complete
3. 🔄 Start the agent: `npm start`
4. 🔄 Test with queries
5. 🔄 Integrate with smart contracts
6. 🔄 Deploy to production

## Support

For issues or questions:
1. Check the logs: `npm run dev` (shows detailed output)
2. Review the code: `src/services/metricsService.ts`
3. Test components: `node test-metrics-new.js`

## License

MIT
