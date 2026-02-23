#!/bin/bash
# ============================================================================
# AI Orchestrator - Uninstallation Script
# ============================================================================
# Cleanly removes AI Orchestrator and all its components.
#
# Usage: ./uninstall.sh [--keep-config] [--keep-deps]
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

# Parse arguments
KEEP_CONFIG=false
KEEP_DEPS=false
FORCE=false

for arg in "$@"; do
    case $arg in
        --keep-config) KEEP_CONFIG=true ;;
        --keep-deps) KEEP_DEPS=true ;;
        --force|-f) FORCE=true ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --keep-config  Keep configuration files (.env, API keys)"
            echo "  --keep-deps    Keep installed dependencies (Homebrew, Python)"
            echo "  --force, -f    Skip confirmation prompts"
            echo "  --help, -h     Show this help message"
            exit 0
            ;;
    esac
done

# Detect installation directory
if [ -n "$INSTALL_DIR" ]; then
    AI_ORCH_DIR="$INSTALL_DIR"
elif [ -f "$HOME/ai-orchestrator/.env" ]; then
    AI_ORCH_DIR="$HOME/ai-orchestrator"
elif [ -f "$(dirname "$0")/.env" ]; then
    AI_ORCH_DIR="$(cd "$(dirname "$0")" && pwd)"
else
    AI_ORCH_DIR="$HOME/ai-orchestrator"
fi

echo ""
echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC}           ${BOLD}AI Orchestrator Uninstallation${NC}                    ${RED}║${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

print_info "Installation directory: $AI_ORCH_DIR"
echo ""

# Confirmation
if [ "$FORCE" != true ]; then
    echo -e "${YELLOW}This will remove:${NC}"
    echo "  • MCP server process"
    echo "  • Launch agent (auto-start)"
    echo "  • Installation directory: $AI_ORCH_DIR"
    echo "  • Cursor MCP configuration"
    if [ "$KEEP_CONFIG" != true ]; then
        echo "  • Configuration files (.env)"
    fi
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_info "Uninstallation cancelled"
        exit 0
    fi
fi

echo ""
print_info "Starting uninstallation..."
echo ""

# Step 1: Stop MCP server
print_info "Stopping MCP server..."
if pgrep -f "mcp_server.server" > /dev/null 2>&1; then
    pkill -f "mcp_server.server" 2>/dev/null || true
    sleep 1
    if pgrep -f "mcp_server.server" > /dev/null 2>&1; then
        pkill -9 -f "mcp_server.server" 2>/dev/null || true
    fi
    print_status "MCP server stopped"
else
    print_info "MCP server not running"
fi

# Step 2: Remove launch agent
print_info "Removing launch agent..."
PLIST_FILE="$HOME/Library/LaunchAgents/com.ai-orchestrator.mcp-server.plist"
if [ -f "$PLIST_FILE" ]; then
    launchctl unload "$PLIST_FILE" 2>/dev/null || true
    rm -f "$PLIST_FILE"
    print_status "Launch agent removed"
else
    print_info "Launch agent not found"
fi

# Step 3: Remove Cursor configuration
print_info "Removing Cursor configuration..."
CURSOR_CONFIG="$HOME/Library/Application Support/Cursor/User/globalStorage/mcp-settings.json"
if [ -f "$CURSOR_CONFIG" ]; then
    # Remove only ai-orchestrator entry, keep other MCP servers
    if command -v python3 &> /dev/null; then
        python3 -c "
import json
try:
    with open('$CURSOR_CONFIG', 'r') as f:
        config = json.load(f)
    if 'mcpServers' in config and 'ai-orchestrator' in config['mcpServers']:
        del config['mcpServers']['ai-orchestrator']
        with open('$CURSOR_CONFIG', 'w') as f:
            json.dump(config, f, indent=2)
        print('Removed ai-orchestrator from Cursor config')
except Exception as e:
    pass
" 2>/dev/null || rm -f "$CURSOR_CONFIG"
    else
        rm -f "$CURSOR_CONFIG"
    fi
    print_status "Cursor configuration cleaned"
else
    print_info "Cursor configuration not found"
fi

# Step 4: Remove .cursorrules
if [ -f "$HOME/.cursorrules" ]; then
    rm -f "$HOME/.cursorrules"
    print_status "Cursor rules removed"
fi

# Step 5: Backup configuration if requested
if [ "$KEEP_CONFIG" = true ] && [ -d "$AI_ORCH_DIR" ]; then
    print_info "Backing up configuration..."
    BACKUP_DIR="$HOME/.ai-orchestrator-backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    [ -f "$AI_ORCH_DIR/.env" ] && cp "$AI_ORCH_DIR/.env" "$BACKUP_DIR/"
    print_status "Configuration backed up to $BACKUP_DIR"
fi

# Step 6: Remove installation directory
print_info "Removing installation directory..."
if [ -d "$AI_ORCH_DIR" ]; then
    rm -rf "$AI_ORCH_DIR"
    print_status "Installation directory removed"
else
    print_info "Installation directory not found"
fi

# Step 7: Clean up dependencies (optional)
if [ "$KEEP_DEPS" != true ]; then
    print_info "Checking for orphaned dependencies..."
    # We don't actually remove Homebrew or Python as they may be used by other apps
    print_info "Skipping dependency removal (may be used by other applications)"
    print_info "To manually remove: brew uninstall python@3.11"
fi

# Step 8: Remove logs and temp files
print_info "Cleaning up temporary files..."
rm -f /tmp/ai-orchestrator-*.log 2>/dev/null || true
rm -f /tmp/ai-orchestrator-*.tmp 2>/dev/null || true
print_status "Temporary files cleaned"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}           ${BOLD}Uninstallation Complete!${NC}                          ${GREEN}║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
print_info "AI Orchestrator has been removed from your system."
if [ "$KEEP_CONFIG" = true ]; then
    print_info "Configuration backed up to: $BACKUP_DIR"
fi
print_info "Restart Cursor IDE to complete removal."
echo ""
print_info "Thank you for using AI Orchestrator!"
