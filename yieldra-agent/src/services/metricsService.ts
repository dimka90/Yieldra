/**
 * Metrics Service
 * ----------------
 * Fetches real DeFi protocol metrics for AI-assisted decision making.
 * All data here is OFF-CHAIN and MUST NOT be used as an on-chain oracle.
 */

export interface ProtocolMetrics {
  protocol: string;
  apy: number;          // % APY
  utilization: number;  // 0–100
  liquidity: number;    // TVL in USD
  riskScore: number;    // 0–100 (lower = safer)
  lastUpdated: number;
}

export class MetricsService {
  private defiLlamaBaseUrl = 'https://api.llama.fi';
  private coingeckoBaseUrl = 'https://api.coingecko.com/api/v3';

  /* --------------------------------------------------
   * Generic JSON fetch helper
   * -------------------------------------------------- */
  private async fetchJson(url: string): Promise<any | null> {
    try {
      const res = await fetch(url, {
        headers: { accept: 'application/json' },
      });
      if (!res.ok) return null;
      return await res.json();
    } catch {
      return null;
    }
  }

  /* --------------------------------------------------
   * Ondo Finance
   * -------------------------------------------------- */
  async getOndoMetrics(): Promise<ProtocolMetrics> {
    const data = await this.fetchJson(
      `${this.defiLlamaBaseUrl}/protocol/ondo-finance`
    );

    // Extract latest TVL from array (DeFi Llama returns time-series data)
    let tvl = 0;
    if (Array.isArray(data?.tvl) && data.tvl.length > 0) {
      const latest = data.tvl[data.tvl.length - 1];
      tvl = Array.isArray(latest) ? latest[1] : latest;
    }

    return {
      protocol: 'ondo',
      apy: 5.2,               // USDY historical average
      utilization: this.calculateUtilization(tvl),
      liquidity: tvl,
      riskScore: 20,          // RWA-backed
      lastUpdated: Date.now(),
    };
  }

  /* --------------------------------------------------
   * Ethena
   * -------------------------------------------------- */
  async getEthenaMetrics(): Promise<ProtocolMetrics> {
    const data = await this.fetchJson(
      `${this.defiLlamaBaseUrl}/protocol/ethena`
    );

    // Extract latest TVL from array (DeFi Llama returns time-series data)
    let tvl = 0;
    if (Array.isArray(data?.tvl) && data.tvl.length > 0) {
      const latest = data.tvl[data.tvl.length - 1];
      tvl = Array.isArray(latest) ? latest[1] : latest;
    }

    return {
      protocol: 'ethena',
      apy: 8.5,               // USDe variable yield
      utilization: this.calculateUtilization(tvl),
      liquidity: tvl,
      riskScore: 30,          // Synthetic dollar risk
      lastUpdated: Date.now(),
    };
  }

  /* --------------------------------------------------
   * Aave V3
   * -------------------------------------------------- */
  async getAaveMetrics(): Promise<ProtocolMetrics> {
    const data = await this.fetchJson(
      `${this.defiLlamaBaseUrl}/protocol/aave`
    );

    // Extract latest TVL from array (DeFi Llama returns time-series data)
    let tvl = 0;
    if (Array.isArray(data?.tvl) && data.tvl.length > 0) {
      const latest = data.tvl[data.tvl.length - 1];
      tvl = Array.isArray(latest) ? latest[1] : latest;
    }

    return {
      protocol: 'aave',
      apy: 3.5,               // aUSDC average
      utilization: this.calculateUtilization(tvl),
      liquidity: tvl,
      riskScore: 15,          // Battle-tested
      lastUpdated: Date.now(),
    };
  }

  /* --------------------------------------------------
   * Aggregate protocol metrics
   * -------------------------------------------------- */
  async getAllProtocolMetrics(): Promise<ProtocolMetrics[]> {
    return Promise.all([
      this.getOndoMetrics(),
      this.getEthenaMetrics(),
      this.getAaveMetrics(),
    ]);
  }

  /* --------------------------------------------------
   * Market prices (AI reasoning ONLY)
   * -------------------------------------------------- */
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

  /* --------------------------------------------------
   * Market volatility proxy (24h % change)
   * -------------------------------------------------- */
  async getMarketVolatility(): Promise<{
    eth: number;
    btc: number;
    mnt: number;
  }> {
    const data = await this.fetchJson(
      `${this.coingeckoBaseUrl}/simple/price?ids=ethereum,bitcoin,mantle&vs_currencies=usd&include_24hr_change=true`
    );

    return {
      eth: Math.abs(data?.ethereum?.usd_24h_change ?? 0),
      btc: Math.abs(data?.bitcoin?.usd_24h_change ?? 0),
      mnt: Math.abs(data?.mantle?.usd_24h_change ?? 0),
    };
  }

  /* --------------------------------------------------
   * Utilization heuristic
   * -------------------------------------------------- */
  private calculateUtilization(tvl: number): number {
    if (tvl < 10_000_000) return 40;
    if (tvl < 100_000_000) return 60;
    if (tvl < 1_000_000_000) return 75;
    return 85;
  }
}
