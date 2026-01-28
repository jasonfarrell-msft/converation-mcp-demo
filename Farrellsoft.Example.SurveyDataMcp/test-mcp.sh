#!/bin/bash

# MCP Server Test Script
# This script demonstrates how to interact with an MCP server using HTTP/SSE transport
# 
# IMPORTANT: The MCP SSE transport requires:
# 1. A persistent SSE connection to /sse that stays open
# 2. Messages sent to /message?sessionId=<id> 
# 3. Responses come back via the SSE stream, NOT as HTTP response bodies

BASE_URL="${1:-http://localhost:5121}"

echo "=== MCP Server Test ==="
echo "Base URL: $BASE_URL"
echo ""
echo "The MCP SSE transport works by:"
echo "1. Establishing an SSE connection to /sse (returns sessionId)"
echo "2. POSTing messages to /message?sessionId=<id>"
echo "3. Receiving responses via the SSE stream"
echo ""
echo "Testing SSE endpoint..."

# Create a temp file for SSE output
SSE_OUTPUT=$(mktemp)

# Start SSE connection in background and capture output
curl -s -N -H "Accept: text/event-stream" "$BASE_URL/sse" > "$SSE_OUTPUT" 2>&1 &
SSE_PID=$!

# Wait for SSE to establish and get session ID
sleep 2

echo "SSE Output:"
cat "$SSE_OUTPUT"
echo ""

# Extract session ID
SESSION_ID=$(grep -o 'sessionId=[^"[:space:]]*' "$SSE_OUTPUT" | head -1 | cut -d'=' -f2)

if [ -z "$SESSION_ID" ]; then
    echo "ERROR: Could not get session ID"
    kill $SSE_PID 2>/dev/null
    rm "$SSE_OUTPUT"
    exit 1
fi

echo "Session ID: $SESSION_ID"
echo ""

# Send initialize request
echo "Sending initialize request..."
curl -s -X POST "$BASE_URL/message?sessionId=$SESSION_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2024-11-05",
      "capabilities": {},
      "clientInfo": {"name": "test-client", "version": "1.0.0"}
    }
  }'
echo ""

sleep 1

# Send initialized notification
echo "Sending initialized notification..."
curl -s -X POST "$BASE_URL/message?sessionId=$SESSION_ID" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "notifications/initialized"}'
echo ""

sleep 1

# List tools
echo "Listing tools..."
curl -s -X POST "$BASE_URL/message?sessionId=$SESSION_ID" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {}}'
echo ""

sleep 1

# Call SayHello
echo "Calling SayHello tool..."
curl -s -X POST "$BASE_URL/message?sessionId=$SESSION_ID" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "id": 3, "method": "tools/call", "params": {"name": "SayHello", "arguments": {"name": "World"}}}'
echo ""

sleep 2

echo ""
echo "=== SSE Stream Output (responses appear here) ==="
cat "$SSE_OUTPUT"

# Cleanup
kill $SSE_PID 2>/dev/null
rm "$SSE_OUTPUT"

echo ""
echo "=== Test Complete ==="
