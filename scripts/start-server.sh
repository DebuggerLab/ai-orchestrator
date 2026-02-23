#!/bin/bash
# ============================================================================
# AI Orchestrator - Start MCP Server
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

# Determine installation directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AI_ORCH_DIR="$(dirname "$SCRIPT_DIR")"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🚀 Starting AI Orchestrator MCP Server"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd "$AI_ORCH_DIR"

# Check if already running
if pgrep -f "mcp_server.server" > /dev/null 2>&1; then
    PID=$(pgrep -f "mcp_server.server")
    print_warn "MCP server is already running (PID: $PID)"
    print_info "Use restart-server.sh to restart"
    exit 0
fi

# Check virtual environment
if [ ! -d "venv" ]; then
    print_warn "Virtual environment not found. Run install.sh first."
    exit 1
fi

# Check .env file
if [ ! -f ".env" ]; then
    print_warn ".env file not found. Run install.sh to configure."
    exit 1
fi

# Create logs directory
mkdir -p logs

# Set environment
export PYTHONPATH="$AI_ORCH_DIR"

# Start server
print_info "Starting server..."
nohup "$AI_ORCH_DIR/venv/bin/python" -m mcp_server.server > "$AI_ORCH_DIR/logs/mcp-server.log" 2>&1 &

sleep 2

# Verify start
if pgrep -f "mcp_server.server" > /dev/null 2>&1; then
    PID=$(pgrep -f "mcp_server.server")
    print_status "MCP server started (PID: $PID)"
    print_info "Logs: $AI_ORCH_DIR/logs/mcp-server.log"
else
    print_warn "MCP server may not have started properly"
    print_info "Check logs: tail -f $AI_ORCH_DIR/logs/mcp-server.log"
    exit 1
fi
