#!/bin/bash
# ============================================================================
# AI Orchestrator - Update Script
# ============================================================================
# Updates AI Orchestrator to the latest version while preserving configuration.
#
# Usage: ./update.sh [--force]
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1" >&2; }
print_info() { echo -e "${CYAN}ℹ${NC} $1"; }
print_warn() { echo -e "${YELLOW}⚠${NC} $1"; }

# Determine script location
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AI_ORCH_DIR="$SCRIPT_DIR"

# Parse arguments
FORCE=false
for arg in "$@"; do
    case $arg in
        --force|-f) FORCE=true ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --force, -f    Force update even if up to date"
            echo "  --help, -h     Show this help message"
            exit 0
            ;;
    esac
done

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}              ${BOLD}AI Orchestrator Update${NC}                         ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

print_info "Installation directory: $AI_ORCH_DIR"

# Check if directory exists
if [ ! -d "$AI_ORCH_DIR" ]; then
    print_error "Installation not found at $AI_ORCH_DIR"
    print_info "Please run install.sh first"
    exit 1
fi

cd "$AI_ORCH_DIR"

# Step 1: Backup configuration
print_info "Backing up configuration..."
BACKUP_DIR="/tmp/ai-orchestrator-backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
[ -f ".env" ] && cp ".env" "$BACKUP_DIR/"
[ -f "mcp_server/.env" ] && cp "mcp_server/.env" "$BACKUP_DIR/mcp_server.env"
print_status "Configuration backed up"

# Step 2: Stop MCP server
print_info "Stopping MCP server..."
if pgrep -f "mcp_server.server" > /dev/null 2>&1; then
    pkill -f "mcp_server.server" 2>/dev/null || true
    sleep 2
    print_status "MCP server stopped"
else
    print_info "MCP server not running"
fi

# Step 3: Pull latest changes
print_info "Pulling latest changes..."
if [ -d ".git" ]; then
    # Check for local changes
    if [ -n "$(git status --porcelain)" ]; then
        print_warn "Local changes detected, stashing..."
        git stash
    fi
    
    # Fetch and check for updates
    git fetch origin
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse @{u} 2>/dev/null || git rev-parse origin/main 2>/dev/null || git rev-parse origin/master)
    
    if [ "$LOCAL" = "$REMOTE" ] && [ "$FORCE" != true ]; then
        print_info "Already up to date"
    else
        CURRENT_BRANCH=$(git branch --show-current)
        git pull origin "$CURRENT_BRANCH" 2>/dev/null || git pull origin main 2>/dev/null || git pull origin master 2>/dev/null
        print_status "Repository updated"
    fi
    
    # Restore stashed changes
    if git stash list | grep -q "stash@{0}"; then
        git stash pop 2>/dev/null || print_warn "Could not restore local changes"
    fi
else
    print_warn "Not a git repository, skipping pull"
fi

# Step 4: Restore configuration
print_info "Restoring configuration..."
[ -f "$BACKUP_DIR/.env" ] && cp "$BACKUP_DIR/.env" ".env"
[ -f "$BACKUP_DIR/mcp_server.env" ] && cp "$BACKUP_DIR/mcp_server.env" "mcp_server/.env"
print_status "Configuration restored"

# Step 5: Update Python dependencies
print_info "Updating Python dependencies..."
if [ -d "venv" ]; then
    source venv/bin/activate
    pip install --upgrade pip -q
    [ -f "requirements.txt" ] && pip install -r requirements.txt --upgrade -q
    [ -f "mcp_server/requirements.txt" ] && pip install -r mcp_server/requirements.txt --upgrade -q
    pip install -e . --upgrade -q
    print_status "Dependencies updated"
else
    print_warn "Virtual environment not found, creating new one..."
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip -q
    [ -f "requirements.txt" ] && pip install -r requirements.txt -q
    [ -f "mcp_server/requirements.txt" ] && pip install -r mcp_server/requirements.txt -q
    pip install -e . -q
    print_status "Virtual environment created and dependencies installed"
fi

# Step 6: Make scripts executable
print_info "Updating script permissions..."
chmod +x *.sh 2>/dev/null || true
chmod +x scripts/*.sh 2>/dev/null || true
chmod +x mcp_server/start.sh 2>/dev/null || true
print_status "Permissions updated"

# Step 7: Restart MCP server
print_info "Starting MCP server..."
export PYTHONPATH="$AI_ORCH_DIR"
mkdir -p logs
nohup "$AI_ORCH_DIR/venv/bin/python" -m mcp_server.server > "$AI_ORCH_DIR/logs/mcp-server.log" 2>&1 &
sleep 2

if pgrep -f "mcp_server.server" > /dev/null 2>&1; then
    print_status "MCP server started"
else
    print_warn "MCP server may not have started properly"
    print_info "Check logs: tail -f $AI_ORCH_DIR/logs/mcp-server.log"
fi

# Step 8: Show version info
echo ""
if [ -f "VERSION" ]; then
    print_info "Version: $(cat VERSION)"
fi

if [ -d ".git" ]; then
    COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    print_info "Commit: $COMMIT"
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}              ${BOLD}Update Complete!${NC}                               ${GREEN}║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
print_info "MCP server is running. Restart Cursor IDE to apply changes."
