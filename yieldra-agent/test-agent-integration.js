#!/usr/bin/env node

/**
 * Test ElizaOS Agent Integration
 * Verifies that the fetchMetricsAction works with the agent
 */

import { fetchMetricsAction } from './dist/src/actions/fetchMetrics.js';

async function testIntegration() {
  console.log('🧪 Testing ElizaOS Agent Integration\n');
  console.log('================================\n');

  try {
    console.log('✓ fetchMetricsAction imported successfully');
    console.log(`  - Action name: ${fetchMetricsAction.name}`);
    console.log(`  - Description: ${fetchMetricsAction.description}`);
    console.log(`  - Similes: ${fetchMetricsAction.similes.join(', ')}\n`);

    // Simulate agent runtime
    const mockRuntime = {
      agentId: 'test-agent',
      character: { name: 'Yieldra' },
    };

    const mockMessage = {
      content: { text: 'Fetch metrics' },
      userId: 'test-user',
    };

    console.log('📊 Testing handler...\n');
    const result = await fetchMetricsAction.handler(mockRuntime, mockMessage);

    console.log('✓ Handler executed successfully\n');
    console.log('Response:');
    console.log(result.text);

    console.log('\n================================');
    console.log('✅ Integration test passed!\n');
    console.log('Next steps:');
    console.log('1. Run: npm start (or bun start)');
    console.log('2. The agent will start and be ready for queries');
    console.log('3. Try: "Fetch the latest protocol metrics"');

  } catch (error) {
    console.error('❌ Integration test failed:', error);
    process.exit(1);
  }
}

testIntegration();
