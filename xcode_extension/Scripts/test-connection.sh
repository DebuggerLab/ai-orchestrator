#!/bin/bash
#
# Test MCP server connection
# Copyright © 2026 DebuggerLab. All rights reserved.
#

# Configuration
MCP_SERVER_URL="${MCP_SERVER_URL:-http://localhost:3000}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Testing MCP Server Connection ===${NC}"
echo ""
echo "Server URL: $MCP_SERVER_URL"
echo ""

# Test basic connectivity
echo -e "${BLUE}Testing connectivity...${NC}"
if curl -s --connect-timeout 5 "$MCP_SERVER_URL" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Server is reachable"
else
    echo -e "${RED}✗${NC} Cannot connect to server"
    echo ""
    echo "Make sure the MCP server is running:"
    echo "  cd /path/to/ai_orchestrator/mcp_server"
    echo "  ./start.sh"
    exit 1
fi

# Test MCP protocol
echo -e "${BLUE}Testing MCP protocol...${NC}"
RESPONSE=$(curl -s -X POST "$MCP_SERVER_URL" \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","id":"test","method":"tools/list","params":{}}' \
    2>/dev/null)

if echo "$RESPONSE" | grep -q '"result"'; then
    echo -e "${GREEN}✓${NC} MCP protocol working"
    
    # List available tools
    echo ""
    echo -e "${BLUE}Available tools:${NC}"
    echo "$RESPONSE" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    tools = data.get('result', {}).get('tools', [])
    for tool in tools:
        print(f\"  - {tool.get('name', 'unknown')}: {tool.get('description', '')}\")
except:
    print('  Unable to parse tools list')
" 2>/dev/null || echo "  Unable to parse response"
else
    echo -e "${YELLOW}!${NC} MCP protocol response unexpected"
    echo "Response: $RESPONSE"
fi

echo ""
echo -e "${GREEN}=== Connection Test Complete ===${NC}"
