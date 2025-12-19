#!/usr/bin/env node

/**
 * Debug script to test API calls directly
 */

async function testFetch() {
  console.log('🔍 Testing Direct API Calls\n');

  // Test 1: Ondo
  console.log('1️⃣  Testing Ondo API:');
  try {
    const res = await fetch('https://api.llama.fi/protocol/ondo-finance', {
      headers: { accept: 'application/json' }
    });
    console.log(`   Status: ${res.status}`);
    if (res.ok) {
      const data = await res.json();
      console.log(`   TVL: ${data.tvl ? 'present' : 'missing'}`);
      console.log(`   APY: ${data.apy ? 'present' : 'missing'}`);
      console.log(`   Data keys: ${Object.keys(data).slice(0, 5).join(', ')}`);
    }
  } catch (error) {
    console.log(`   Error: ${error.message}`);
  }
  console.log();

  // Test 2: Ethena
  console.log('2️⃣  Testing Ethena API:');
  try {
    const res = await fetch('https://api.llama.fi/protocol/ethena', {
      headers: { accept: 'application/json' }
    });
    console.log(`   Status: ${res.status}`);
    if (res.ok) {
      const data = await res.json();
      console.log(`   TVL: ${data.tvl ? 'present' : 'missing'}`);
      console.log(`   APY: ${data.apy ? 'present' : 'missing'}`);
      console.log(`   Data keys: ${Object.keys(data).slice(0, 5).join(', ')}`);
    }
  } catch (error) {
    console.log(`   Error: ${error.message}`);
  }
  console.log();

  // Test 3: Aave
  console.log('3️⃣  Testing Aave API:');
  try {
    const res = await fetch('https://api.llama.fi/protocol/aave', {
      headers: { accept: 'application/json' }
    });
    console.log(`   Status: ${res.status}`);
    if (res.ok) {
      const data = await res.json();
      console.log(`   TVL: ${data.tvl ? 'present' : 'missing'}`);
      console.log(`   APY: ${data.apy ? 'present' : 'missing'}`);
      console.log(`   Data keys: ${Object.keys(data).slice(0, 5).join(', ')}`);
    }
  } catch (error) {
    console.log(`   Error: ${error.message}`);
  }
  console.log();

  // Test 4: CoinGecko
  console.log('4️⃣  Testing CoinGecko API:');
  try {
    const res = await fetch('https://api.coingecko.com/api/v3/simple/price?ids=ethereum,bitcoin,mantle&vs_currencies=usd', {
      headers: { accept: 'application/json' }
    });
    console.log(`   Status: ${res.status}`);
    if (res.ok) {
      const data = await res.json();
      console.log(`   ETH: $${data.ethereum?.usd}`);
      console.log(`   BTC: $${data.bitcoin?.usd}`);
      console.log(`   MNT: $${data.mantle?.usd}`);
    }
  } catch (error) {
    console.log(`   Error: ${error.message}`);
  }
}

testFetch();
