#!/bin/bash

# Simple test to verify agent is running and responding

echo "🤖 Yieldra Agent Simple Test"
echo "================================"
echo ""

# Check if agent is running
echo "1️⃣  Checking if agent is running..."
RESPONSE=$(curl -s http://localhost:3001/api/agents)

if echo "$RESPONSE" | grep -q "Yieldra"; then
    echo "✓ Agent is running!"
    echo ""
    
    # Extract agent ID
    AGENT_ID=$(echo "$RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    echo "  Agent ID: $AGENT_ID"
    echo ""
else
    echo "❌ Agent is not responding"
    echo "Make sure the agent is running with: npm start"
    exit 1
fi

# Check health endpoint
echo "2️⃣  Checking agent health..."
HEALTH=$(curl -s http://localhost:3001/health)

if echo "$HEALTH" | grep -q "ok"; then
    echo "✓ Agent health check passed"
    echo ""
else
    echo "⚠ Health check response: $HEALTH"
    echo ""
fi

# Show agent info
echo "3️⃣  Agent Information:"
echo "$RESPONSE" | grep -o '"name":"[^"]*"' | head -1
echo "$RESPONSE" | grep -o '"characterName":"[^"]*"' | head -1
echo ""

echo "================================"
echo "✅ Agent is running and ready!"
echo ""
echo "You can interact with the agent at:"
echo "  - Web UI: http://localhost:3001"
echo "  - API: http://localhost:3001/api"
echo ""
echo "Try asking the agent:"
echo "  - 'Fetch metrics'"
echo "  - 'Get protocol data'"
echo "  - 'Check yields'"
echo "  - 'Analyze protocols'"
