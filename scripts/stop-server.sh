#!/bin/bash
# ============================================================================
# AI Orchestrator - Stop MCP Server
# ============================================================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✓${NC} $1"; }
print_info() { echo -e "${CYAN}ℹ${NC} $1"; }
print_warn() { echo -e "${YELLOW}⚠${NC} $1"; }

FORCE=false
[ "$1" = "--force" ] || [ "$1" = "-f" ] && FORCE=true

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🛑 Stopping AI Orchestrator MCP Server"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if running
if ! pgrep -f "mcp_server.server" > /dev/null 2>&1; then
    print_info "MCP server is not running"
    exit 0
fi

PID=$(pgrep -f "mcp_server.server")
print_info "Found MCP server (PID: $PID)"

# Graceful stop
print_info "Sending SIGTERM..."
kill "$PID" 2>/dev/null || true
sleep 2

# Check if stopped
if ! pgrep -f "mcp_server.server" > /dev/null 2>&1; then
    print_status "MCP server stopped gracefully"
    exit 0
fi

# Force kill if needed
if [ "$FORCE" = true ]; then
    print_warn "Forcing termination..."
    kill -9 "$PID" 2>/dev/null || true
    sleep 1
    print_status "MCP server terminated"
else
    print_warn "Server still running. Use --force to force termination."
    exit 1
fi
