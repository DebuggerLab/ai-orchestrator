#!/bin/bash
# ============================================================================
# AI Orchestrator - Server Status
# ============================================================================

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Determine installation directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AI_ORCH_DIR="$(dirname "$SCRIPT_DIR")"

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}            ${BOLD}AI Orchestrator Status${NC}                           ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# MCP Server Status
echo -e "${BOLD}MCP Server:${NC}"
if pgrep -f "mcp_server.server" > /dev/null 2>&1; then
    PID=$(pgrep -f "mcp_server.server")
    echo -e "  Status:  ${GREEN}● Running${NC} (PID: $PID)"
    
    # Get memory usage
    if [[ "$OSTYPE" == "darwin"* ]]; then
        MEM=$(ps -o rss= -p "$PID" 2>/dev/null | awk '{printf "%.1f MB", $1/1024}')
    else
        MEM=$(ps -o rss= -p "$PID" 2>/dev/null | awk '{printf "%.1f MB", $1/1024}')
    fi
    echo -e "  Memory:  $MEM"
    
    # Get uptime
    if [[ "$OSTYPE" == "darwin"* ]]; then
        STARTED=$(ps -o lstart= -p "$PID" 2>/dev/null)
    else
        STARTED=$(ps -o lstart= -p "$PID" 2>/dev/null)
    fi
    echo -e "  Started: $STARTED"
else
    echo -e "  Status:  ${RED}● Stopped${NC}"
fi
echo ""

# Launch Agent Status
echo -e "${BOLD}Auto-Start:${NC}"
PLIST="$HOME/Library/LaunchAgents/com.ai-orchestrator.mcp-server.plist"
if [ -f "$PLIST" ]; then
    if launchctl list | grep -q "com.ai-orchestrator.mcp-server"; then
        echo -e "  Status:  ${GREEN}● Enabled${NC}"
    else
        echo -e "  Status:  ${YELLOW}○ Installed but not loaded${NC}"
    fi
else
    echo -e "  Status:  ${DIM}○ Not configured${NC}"
fi
echo ""

# Installation Info
echo -e "${BOLD}Installation:${NC}"
echo "  Directory: $AI_ORCH_DIR"

if [ -f "$AI_ORCH_DIR/.env" ]; then
    echo -e "  Config:    ${GREEN}✓${NC} .env present"
else
    echo -e "  Config:    ${RED}✗${NC} .env missing"
fi

if [ -d "$AI_ORCH_DIR/venv" ]; then
    echo -e "  Venv:      ${GREEN}✓${NC} Present"
else
    echo -e "  Venv:      ${RED}✗${NC} Missing"
fi
echo ""

# Version Info
echo -e "${BOLD}Version Info:${NC}"
if [ -d "$AI_ORCH_DIR/.git" ]; then
    cd "$AI_ORCH_DIR"
    BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
    COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    echo "  Branch:  $BRANCH"
    echo "  Commit:  $COMMIT"
else
    echo "  ${DIM}Not a git repository${NC}"
fi
echo ""

# Log Files
echo -e "${BOLD}Log Files:${NC}"
if [ -f "$AI_ORCH_DIR/logs/mcp-server.log" ]; then
    SIZE=$(du -h "$AI_ORCH_DIR/logs/mcp-server.log" | cut -f1)
    echo "  Server Log: $AI_ORCH_DIR/logs/mcp-server.log ($SIZE)"
else
    echo -e "  Server Log: ${DIM}No logs yet${NC}"
fi
if [ -f "$AI_ORCH_DIR/logs/mcp-server.error.log" ]; then
    SIZE=$(du -h "$AI_ORCH_DIR/logs/mcp-server.error.log" | cut -f1)
    ERRORS=$(wc -l < "$AI_ORCH_DIR/logs/mcp-server.error.log" | tr -d ' ')
    echo "  Error Log:  $AI_ORCH_DIR/logs/mcp-server.error.log ($SIZE, $ERRORS lines)"
fi
echo ""

# Quick Commands
echo -e "${BOLD}Quick Commands:${NC}"
echo "  Start:    $SCRIPT_DIR/start-server.sh"
echo "  Stop:     $SCRIPT_DIR/stop-server.sh"
echo "  Restart:  $SCRIPT_DIR/restart-server.sh"
echo "  Logs:     $SCRIPT_DIR/logs.sh"
echo ""
