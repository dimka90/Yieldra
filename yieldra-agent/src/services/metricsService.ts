/**
 * MetricsService
 * --------------
 * Off-chain metrics provider for AI reasoning ONLY.
 * Not used for on-chain execution or oracle validation.
 */

export interface ProtocolMetrics {
  protocol: string;
  apy: number;           // %
  utilization: number;   // %
  liquidity: number;     // USD
  riskScore: number;     // 0–100 (lower = safer)
  lastUpdated: number;
}

export class MetricsService {
  private defiLlamaBaseUrl = 'https://api.llama.fi';
  private coingeckoBaseUrl = 'https://api.coingecko.com/api/v3';

  constructor() {}

  /* =========================
     Generic JSON Fetch Helper
     ========================= */
  private async fetchJson(url: string): Promise<any | null> {
    try {
      const res = await fetch(url, {
        headers: { accept: 'application/json' }
      });
      if (!res.ok) return null;
      return await res.json();
    } catch {
      return null;
    }
  }

  /* =========================
     TVL Normalization Helper
     ========================= */
  private extractTVL(data: any): number {
    if (!data?.tvl) return 0;

    // Case 1: TVL is a number
    if (typeof data.tvl === 'number') {
      return data.tvl;
    }

    // Case 2: TVL is an array (historical)
    if (Array.isArray(data.tvl)) {
      const latest = data.tvl[data.tvl.length - 1];
      return latest?.totalLiquidityUSD ?? 0;
    }

    // Case 3: TVL is an object (chain breakdown)
    if (typeof data.tvl === 'object') {
      return Object.values(data.tvl)
        .filter(v => typeof v === 'number')
        .reduce((a, b) => a + b, 0);
    }

    return 0;
  }

  /* =========================
     Utilization Estimator
     ========================= */
  private calculateUtilization(tvl: number): number {
    if (tvl < 1_000_000) return 40;
    if (tvl < 10_000_000) return 60;
    if (tvl < 100_000_000) return 75;
    return 85;
  }

  /* =========================
     Ondo Finance (USDY)
     ========================= */
  async getOndoMetrics(): Promise<ProtocolMetrics> {
    const data = await this.fetchJson(
      `${this.defiLlamaBaseUrl}/protocol/ondo-finance`
    );

    const tvl = this.extractTVL(data);

    return {
      protocol: 'ondo',
      apy: 5.2,  // USDY historical average (APY not in DeFi Llama API)
      utilization: this.calculateUtilization(tvl),
      liquidity: tvl,  // Real TVL from API
      riskScore: 20,
      lastUpdated: Date.now(),
    };
  }

  /* =========================
     Ethena (USDe)
     ========================= */
  async getEthenaMetrics(): Promise<ProtocolMetrics> {
    const data = await this.fetchJson(
      `${this.defiLlamaBaseUrl}/protocol/ethena`
    );

    const tvl = this.extractTVL(data);

    return {
      protocol: 'ethena',
      apy: 8.5,  // USDe variable yield (APY not in DeFi Llama API)
      utilization: this.calculateUtilization(tvl),
      liquidity: tvl,  // Real TVL from API
      riskScore: 30,
      lastUpdated: Date.now(),
    };
  }

  /* =========================
     Aave V3
     ========================= */
  async getAaveMetrics(): Promise<ProtocolMetrics> {
    const data = await this.fetchJson(
      `${this.defiLlamaBaseUrl}/protocol/aave`
    );

    const tvl = this.extractTVL(data);

    return {
      protocol: 'aave',
      apy: 3.5,  // aUSDC average (APY not in DeFi Llama API)
      utilization: this.calculateUtilization(tvl),
      liquidity: tvl,  // Real TVL from API
      riskScore: 15,
      lastUpdated: Date.now(),
    };
  }

  /* =========================
     Aggregate Metrics
     ========================= */
  async getAllMetrics(): Promise<ProtocolMetrics[]> {
    return Promise.all([
      this.getOndoMetrics(),
      this.getEthenaMetrics(),
      this.getAaveMetrics(),
    ]);
  }

  /* =========================
     Market Prices (AI ONLY)
     ========================= */
  async getMarketPrices(): Promise<{
    eth: number;
    btc: number;
    mnt: number;
  }> {
    const data = await this.fetchJson(
      `${this.coingeckoBaseUrl}/simple/price?ids=ethereum,bitcoin,mantle&vs_currencies=usd`
    );

    return {
      eth: data?.ethereum?.usd ?? 2000,
      btc: data?.bitcoin?.usd ?? 40000,
      mnt: data?.mantle?.usd ?? 1.5,
    };
  }

  /* =========================
     Market Volatility (AI ONLY)
     ========================= */
  async getMarketVolatility(): Promise<{
    ethVolatility: number;
    btcVolatility: number;
    mntVolatility: number;
  }> {
    const data = await this.fetchJson(
      `${this.coingeckoBaseUrl}/simple/price?ids=ethereum,bitcoin,mantle&vs_currencies=usd&include_24hr_change=true`
    );

    return {
      ethVolatility: Math.abs(data?.ethereum?.usd_24h_change ?? 2.3) * 100,
      btcVolatility: Math.abs(data?.bitcoin?.usd_24h_change ?? 2.5) * 100,
      mntVolatility: Math.abs(data?.mantle?.usd_24h_change ?? 1.8) * 100,
    };
  }
}
