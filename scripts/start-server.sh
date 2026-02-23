#!/bin/bash
# ============================================================================
# AI Orchestrator - Start MCP Server
# ============================================================================
# 
# This script starts the MCP server for integration with Cursor IDE and other
# MCP-compatible tools.
#
# NOTE: MCP servers communicate via stdio (stdin/stdout), not HTTP. This means:
# - The server doesn't listen on a port
# - Logs are written to logs/mcp-server.log instead of stdout
# - Cursor IDE communicates directly via the process's stdin/stdout
#
# Usage:
#   ./scripts/start-server.sh           # Start in background (for Cursor)
#   ./scripts/start-server.sh --fg      # Start in foreground (for debugging)
#
# ============================================================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✓${NC} $1"; }
print_info() { echo -e "${CYAN}ℹ${NC} $1"; }
print_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

# Determine installation directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AI_ORCH_DIR="$(dirname "$SCRIPT_DIR")"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🚀 Starting AI Orchestrator MCP Server"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd "$AI_ORCH_DIR"

# Parse arguments
FOREGROUND=false
if [ "$1" == "--fg" ] || [ "$1" == "--foreground" ]; then
    FOREGROUND=true
fi

# Check if already running
if pgrep -f "mcp_server.server" > /dev/null 2>&1; then
    PID=$(pgrep -f "mcp_server.server")
    print_warn "MCP server is already running (PID: $PID)"
    print_info "Use restart-server.sh to restart, or stop-server.sh to stop"
    exit 0
fi

# Check virtual environment
if [ ! -d "venv" ]; then
    print_error "Virtual environment not found. Run install.sh first."
    exit 1
fi

# Check .env file
if [ ! -f ".env" ]; then
    print_warn ".env file not found. Run install.sh to configure."
    print_info "Creating .env from .env.example..."
    if [ -f ".env.example" ]; then
        cp ".env.example" ".env"
        print_status "Created .env file. Please configure your API keys."
    else
        print_error "No .env.example found. Cannot continue."
        exit 1
    fi
fi

# Create logs directory
mkdir -p "$AI_ORCH_DIR/logs"

# Set environment
export PYTHONPATH="$AI_ORCH_DIR"

# Load .env file
if [ -f "$AI_ORCH_DIR/.env" ]; then
    set -a
    source "$AI_ORCH_DIR/.env"
    set +a
fi

# Verify Python dependencies
print_info "Checking dependencies..."
if ! "$AI_ORCH_DIR/venv/bin/python" -c "import mcp; import ai_orchestrator" 2>/dev/null; then
    print_error "Required Python packages not found. Run install.sh first."
    exit 1
fi
print_status "Dependencies verified"

if [ "$FOREGROUND" = true ]; then
    # Run in foreground (for debugging)
    print_info "Starting server in foreground mode..."
    print_info "Press Ctrl+C to stop"
    echo ""
    "$AI_ORCH_DIR/venv/bin/python" -m mcp_server.server
else
    # Start server in background
    print_info "Starting server in background..."
    
    # Use nohup but redirect stdin from /dev/null and stdout/stderr to log
    # Note: MCP servers need stdin/stdout for communication with clients
    # When started standalone, we redirect to ensure clean daemon behavior
    nohup "$AI_ORCH_DIR/venv/bin/python" -m mcp_server.server \
        < /dev/null \
        >> "$AI_ORCH_DIR/logs/mcp-server-stdout.log" 2>&1 &
    
    SERVER_PID=$!
    
    # Wait briefly for server to initialize
    sleep 2
    
    # Verify start
    if kill -0 $SERVER_PID 2>/dev/null; then
        print_status "MCP server started (PID: $SERVER_PID)"
        echo ""
        print_info "Server logs: $AI_ORCH_DIR/logs/mcp-server.log"
        print_info "Stdout log:  $AI_ORCH_DIR/logs/mcp-server-stdout.log"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  📝 Note: MCP servers communicate via stdio, not HTTP ports"
        echo "  Cursor IDE will connect directly via the process"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        # Show recent log entries
        if [ -f "$AI_ORCH_DIR/logs/mcp-server.log" ]; then
            echo ""
            print_info "Recent log entries:"
            tail -5 "$AI_ORCH_DIR/logs/mcp-server.log" 2>/dev/null || true
        fi
    else
        print_error "MCP server may not have started properly"
        print_info "Check logs: tail -f $AI_ORCH_DIR/logs/mcp-server.log"
        
        # Show any error output
        if [ -f "$AI_ORCH_DIR/logs/mcp-server-stdout.log" ]; then
            echo ""
            print_info "Recent output:"
            tail -10 "$AI_ORCH_DIR/logs/mcp-server-stdout.log" 2>/dev/null || true
        fi
        exit 1
    fi
fi
