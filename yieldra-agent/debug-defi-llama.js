#!/usr/bin/env node

async function testDeFiLlama() {
  console.log('Testing DeFi Llama API responses...\n');

  const protocols = ['aave', 'ondo', 'ethena'];

  for (const protocol of protocols) {
    console.log(`\n📊 Testing ${protocol}:`);
    try {
      const response = await fetch(`https://api.llama.fi/protocol/${protocol}`);
      console.log(`   Status: ${response.status}`);
      
      if (!response.ok) {
        const text = await response.text();
        console.log(`   Error response: ${text}`);
        continue;
      }

      const data = await response.json();
      console.log(`   Keys: ${Object.keys(data).join(', ')}`);
      
      if (data.tvl) {
        console.log(`   TVL type: ${Array.isArray(data.tvl) ? 'array' : typeof data.tvl}`);
        if (Array.isArray(data.tvl)) {
          console.log(`   TVL length: ${data.tvl.length}`);
          console.log(`   First TVL entry: ${JSON.stringify(data.tvl[0])}`);
          console.log(`   Last TVL entry: ${JSON.stringify(data.tvl[data.tvl.length - 1])}`);
        }
      }
      
      if (data.apy) {
        console.log(`   APY: ${data.apy}`);
      }
    } catch (error) {
      console.error(`   Error: ${error.message}`);
    }
  }
}

await testDeFiLlama();
