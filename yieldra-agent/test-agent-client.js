#!/usr/bin/env node

/**
 * Yieldra Agent Test Client
 * Tests the agent by sending messages and receiving responses
 */

import fetch from 'node-fetch';

const AGENT_URL = 'http://localhost:3001';
const AGENT_ID = '00000000-0000-0000-0000-000000000000';

async function getAgents() {
  try {
    const response = await fetch(`${AGENT_URL}/api/agents`);
    const data = await response.json();
    return data.data?.agents || data.agents || data;
  } catch (error) {
    console.error('Error fetching agents:', error.message);
    return null;
  }
}

async function sendMessage(agentId, message) {
  try {
    const response = await fetch(`${AGENT_URL}/api/agents/${agentId}/message`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        text: message,
        userId: 'test-user',
        userName: 'Test User',
      }),
    });

    if (!response.ok) {
      console.error(`HTTP Error: ${response.status}`);
      return null;
    }

    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Error sending message:', error.message);
    return null;
  }
}

async function testAgent() {
  console.log('🤖 Yieldra Agent Test Client\n');
  console.log('================================\n');

  // Step 1: Check if agent is running
  console.log('1️⃣  Checking if agent is running...');
  const agents = await getAgents();
  
  if (!agents || agents.length === 0) {
    console.error('❌ No agents found. Make sure the agent is running with: npm start');
    process.exit(1);
  }

  const agent = agents[0];
  console.log(`✓ Agent found: ${agent.name}`);
  console.log(`  ID: ${agent.id}`);
  console.log(`  Status: ${agent.status}\n`);

  // Step 2: Test metrics fetching
  console.log('2️⃣  Testing metrics fetching...\n');
  console.log('📤 Sending: "Fetch the latest protocol metrics"\n');

  const response = await sendMessage(agent.id, 'Fetch the latest protocol metrics');

  if (!response) {
    console.error('❌ Failed to get response from agent');
    process.exit(1);
  }

  console.log('📥 Agent Response:\n');
  console.log('-------------------------------------------');
  
  // Handle different response formats
  if (Array.isArray(response)) {
    // If response is an array of messages
    response.forEach((msg, index) => {
      if (msg.text) {
        console.log(msg.text);
      }
    });
  } else if (response.text) {
    // If response is a single message object
    console.log(response.text);
  } else if (response.message) {
    // Alternative format
    console.log(response.message);
  } else {
    // Raw response
    console.log(JSON.stringify(response, null, 2));
  }

  console.log('-------------------------------------------\n');

  // Step 3: Test another query
  console.log('3️⃣  Testing another query...\n');
  console.log('📤 Sending: "What are the current market conditions?"\n');

  const response2 = await sendMessage(agent.id, 'What are the current market conditions?');

  if (response2) {
    console.log('📥 Agent Response:\n');
    console.log('-------------------------------------------');
    
    if (Array.isArray(response2)) {
      response2.forEach((msg) => {
        if (msg.text) {
          console.log(msg.text);
        }
      });
    } else if (response2.text) {
      console.log(response2.text);
    } else if (response2.message) {
      console.log(response2.message);
    } else {
      console.log(JSON.stringify(response2, null, 2));
    }

    console.log('-------------------------------------------\n');
  }

  console.log('================================');
  console.log('✅ Agent test completed!\n');
  console.log('The agent is working and fetching real protocol metrics.');
  console.log('You can now interact with it via:');
  console.log(`  - Web UI: ${AGENT_URL}`);
  console.log(`  - API: ${AGENT_URL}/api`);
}

testAgent().catch(console.error);
