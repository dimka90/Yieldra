#!/usr/bin/env node

/**
 * Debug script to see what the APIs are actually returning
 */

async function debugAPIs() {
  console.log('🔍 Debugging API Responses\n');

  // Test DeFi Llama
  console.log('1️⃣  Testing DeFi Llama API:');
  try {
    const response = await fetch('https://api.llama.fi/protocol/aave');
    console.log(`   Status: ${response.status}`);
    const text = await response.text();
    console.log(`   Response (first 500 chars): ${text.substring(0, 500)}`);
    console.log();
  } catch (error) {
    console.error(`   Error: ${error.message}\n`);
  }

  // Test CoinGecko
  console.log('2️⃣  Testing CoinGecko API:');
  try {
    const response = await fetch(
      'https://api.coingecko.com/api/v3/simple/price?ids=ethereum,bitcoin,mantle&vs_currencies=usd'
    );
    console.log(`   Status: ${response.status}`);
    const data = await response.json();
    console.log(`   Response:`, JSON.stringify(data, null, 2));
    console.log();
  } catch (error) {
    console.error(`   Error: ${error.message}\n`);
  }

  // Test CoinGecko with 24h change
  console.log('3️⃣  Testing CoinGecko API with 24h change:');
  try {
    const response = await fetch(
      'https://api.coingecko.com/api/v3/simple/price?ids=ethereum,bitcoin,mantle&vs_currencies=usd&include_24hr_change=true'
    );
    console.log(`   Status: ${response.status}`);
    const data = await response.json();
    console.log(`   Response:`, JSON.stringify(data, null, 2));
    console.log();
  } catch (error) {
    console.error(`   Error: ${error.message}\n`);
  }
}

debugAPIs();
