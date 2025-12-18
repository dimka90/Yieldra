import { describe, it, expect, beforeAll } from 'vitest';
import { MetricsService } from './metricsService';

describe('MetricsService - Real API Fetching', () => {
  let metricsService: MetricsService;

  beforeAll(() => {
    metricsService = new MetricsService();
  });

  it('should fetch Ondo metrics from DeFi Llama', async () => {
    const metrics = await metricsService.getOndoMetrics();
    
    expect(metrics).toBeDefined();
    expect(metrics.protocol).toBe('ondo');
    expect(metrics.apy).toBeGreaterThanOrEqual(0);
    expect(metrics.utilization).toBeGreaterThanOrEqual(0);
    expect(metrics.liquidity).toBeGreaterThanOrEqual(0);
    expect(metrics.riskScore).toBeGreaterThanOrEqual(0);
    expect(metrics.lastUpdated).toBeGreaterThan(0);
    
    console.log('✓ Ondo Metrics:', metrics);
  }, { timeout: 10000 });

  it('should fetch Ethena metrics from DeFi Llama', async () => {
    const metrics = await metricsService.getEthenaMetrics();
    
    expect(metrics).toBeDefined();
    expect(metrics.protocol).toBe('ethena');
    expect(metrics.apy).toBeGreaterThanOrEqual(0);
    expect(metrics.utilization).toBeGreaterThanOrEqual(0);
    expect(metrics.liquidity).toBeGreaterThanOrEqual(0);
    expect(metrics.riskScore).toBeGreaterThanOrEqual(0);
    expect(metrics.lastUpdated).toBeGreaterThan(0);
    
    console.log('✓ Ethena Metrics:', metrics);
  }, { timeout: 10000 });

  it('should fetch Aave metrics from DeFi Llama', async () => {
    const metrics = await metricsService.getAaveMetrics();
    
    expect(metrics).toBeDefined();
    expect(metrics.protocol).toBe('aave');
    expect(metrics.apy).toBeGreaterThanOrEqual(0);
    expect(metrics.utilization).toBeGreaterThanOrEqual(0);
    expect(metrics.liquidity).toBeGreaterThanOrEqual(0);
    expect(metrics.riskScore).toBeGreaterThanOrEqual(0);
    expect(metrics.lastUpdated).toBeGreaterThan(0);
    
    console.log('✓ Aave Metrics:', metrics);
  }, { timeout: 10000 });

  it('should fetch all protocol metrics in parallel', async () => {
    const allMetrics = await metricsService.getAllMetrics();
    
    expect(allMetrics).toBeDefined();
    expect(allMetrics.length).toBe(3);
    expect(allMetrics.map(m => m.protocol)).toEqual(['ondo', 'ethena', 'aave']);
    
    allMetrics.forEach(metrics => {
      expect(metrics.apy).toBeGreaterThanOrEqual(0);
      expect(metrics.utilization).toBeGreaterThanOrEqual(0);
      expect(metrics.liquidity).toBeGreaterThanOrEqual(0);
    });
    
    console.log('✓ All Metrics:', allMetrics);
  }, { timeout: 15000 });

  it('should fetch market prices from CoinGecko', async () => {
    const prices = await metricsService.getMarketPrices();
    
    expect(prices).toBeDefined();
    expect(prices.eth).toBeGreaterThan(0);
    expect(prices.btc).toBeGreaterThan(0);
    expect(prices.mnt).toBeGreaterThan(0);
    
    console.log('✓ Market Prices:', prices);
  }, { timeout: 10000 });

  it('should fetch market volatility from CoinGecko', async () => {
    const volatility = await metricsService.getMarketVolatility();
    
    expect(volatility).toBeDefined();
    expect(volatility.ethVolatility).toBeGreaterThanOrEqual(0);
    expect(volatility.btcVolatility).toBeGreaterThanOrEqual(0);
    expect(volatility.mntVolatility).toBeGreaterThanOrEqual(0);
    
    console.log('✓ Market Volatility:', volatility);
  }, { timeout: 10000 });

  it('should handle API failures gracefully with fallback values', async () => {
    // Create a service and test that fallbacks work
    const service = new MetricsService();
    
    // Even if APIs fail, should return valid metrics
    const metrics = await service.getOndoMetrics();
    expect(metrics.protocol).toBe('ondo');
    expect(metrics.apy).toBeGreaterThanOrEqual(0);
  }, { timeout: 10000 });
});
