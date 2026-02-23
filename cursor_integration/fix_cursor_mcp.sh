#!/bin/bash
# ============================================================================
# Cursor MCP Fix Script
# ============================================================================
# This script fixes Cursor IDE MCP integration by creating the correct
# mcp.json configuration file at ~/.cursor/mcp.json
#
# Usage: ./fix_cursor_mcp.sh [OPTIONS]
#
# Options:
#   --install-dir PATH    Specify AI Orchestrator installation directory
#   --dry-run             Show what would be done without making changes
#   --force               Overwrite existing configuration without backup
#
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

# Configuration
CURSOR_CONFIG_DIR="$HOME/.cursor"
MCP_JSON_FILE="$CURSOR_CONFIG_DIR/mcp.json"
BACKUP_DIR="$HOME/.cursor/backups"

# Default options
DRY_RUN=false
FORCE=false
INSTALL_DIR=""

# ============================================================================
# Helper Functions
# ============================================================================
print_header() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}           ${WHITE}${BOLD}Cursor MCP Configuration Fix Tool${NC}          ${GREEN}║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${CYAN}▶${NC} ${WHITE}$1${NC}"
}

print_success() {
    echo -e "  ${GREEN}✅${NC} $1"
}

print_info() {
    echo -e "  ${BLUE}ℹ️${NC} $1"
}

print_warn() {
    echo -e "  ${YELLOW}⚠️${NC} $1"
}

print_error() {
    echo -e "  ${RED}❌${NC} $1"
}

# ============================================================================
# Parse Arguments
# ============================================================================
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --install-dir)
                INSTALL_DIR="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    echo "Usage: ./fix_cursor_mcp.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --install-dir PATH    Specify AI Orchestrator installation directory"
    echo "  --dry-run             Show what would be done without making changes"
    echo "  --force               Overwrite existing configuration without backup"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Example:"
    echo "  ./fix_cursor_mcp.sh --install-dir ~/my-ai-orchestrator"
}

# ============================================================================
# Find Installation Directory
# ============================================================================
find_install_dir() {
    if [ -n "$INSTALL_DIR" ] && [ -f "$INSTALL_DIR/mcp_server/server.py" ]; then
        return 0
    fi
    
    # Search in common locations
    local possible_dirs=(
        "$HOME/ai-orchestrator"
        "$HOME/ai_orchestrator"
        "/home/ubuntu/ai_orchestrator"
        "$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)"
    )
    
    for dir in "${possible_dirs[@]}"; do
        if [ -f "$dir/mcp_server/server.py" ]; then
            INSTALL_DIR="$dir"
            return 0
        fi
    done
    
    return 1
}

# ============================================================================
# Detect Python Command
# ============================================================================
detect_python() {
    # First, check for venv Python
    if [ -f "$INSTALL_DIR/venv/bin/python" ]; then
        echo "$INSTALL_DIR/venv/bin/python"
        return
    fi
    
    if [ -f "$INSTALL_DIR/venv/bin/python3" ]; then
        echo "$INSTALL_DIR/venv/bin/python3"
        return
    fi
    
    # Check for system Python
    if command -v python3 &>/dev/null; then
        echo "python3"
        return
    fi
    
    if command -v python &>/dev/null; then
        echo "python"
        return
    fi
    
    echo ""
}

# ============================================================================
# Backup Existing Configuration
# ============================================================================
backup_existing() {
    if [ -f "$MCP_JSON_FILE" ]; then
        if [ "$FORCE" = true ]; then
            print_warn "Skipping backup (--force mode)"
            return 0
        fi
        
        mkdir -p "$BACKUP_DIR"
        local backup_file="$BACKUP_DIR/mcp.json.backup.$(date +%Y%m%d_%H%M%S)"
        
        if [ "$DRY_RUN" = true ]; then
            print_info "[DRY-RUN] Would backup to: $backup_file"
        else
            cp "$MCP_JSON_FILE" "$backup_file"
            print_success "Backed up existing config to: $backup_file"
        fi
    fi
}

# ============================================================================
# Create MCP Configuration
# ============================================================================
create_mcp_config() {
    local python_cmd=$(detect_python)
    
    if [ -z "$python_cmd" ]; then
        print_error "Could not find Python installation"
        return 1
    fi
    
    print_info "Using Python: $python_cmd"
    
    # Create the configuration
    local mcp_config='{
  "mcpServers": {
    "ai-orchestrator": {
      "command": "'"$python_cmd"'",
      "args": [
        "-m",
        "mcp_server.server"
      ],
      "cwd": "'"$INSTALL_DIR"'",
      "env": {
        "PYTHONPATH": "'"$INSTALL_DIR"'"
      }
    }
  }
}'

    echo ""
    echo -e "  ${WHITE}Generated configuration:${NC}"
    echo -e "${CYAN}  ─────────────────────────────────────────────────${NC}"
    echo "$mcp_config" | while IFS= read -r line; do
        echo -e "  ${DIM}$line${NC}"
    done
    echo -e "${CYAN}  ─────────────────────────────────────────────────${NC}"
    echo ""
    
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY-RUN] Would write to: $MCP_JSON_FILE"
        return 0
    fi
    
    # Create directory if needed
    mkdir -p "$CURSOR_CONFIG_DIR"
    
    # Write configuration
    echo "$mcp_config" > "$MCP_JSON_FILE"
    print_success "Configuration written to: $MCP_JSON_FILE"
}

# ============================================================================
# Migrate Old Configuration
# ============================================================================
migrate_old_config() {
    local old_locations=(
        "$HOME/Library/Application Support/Cursor/User/globalStorage/mcp-settings.json"
        "$HOME/Library/Application Support/Cursor/User/settings.json"
    )
    
    for old_file in "${old_locations[@]}"; do
        if [ -f "$old_file" ]; then
            print_warn "Found deprecated config at: $old_file"
            
            if [ "$DRY_RUN" = true ]; then
                print_info "[DRY-RUN] Would keep old file as reference"
            else
                # Don't delete, just notify
                print_info "Old config left in place (harmless, but not used by Cursor)"
            fi
        fi
    done
}

# ============================================================================
# Verify Configuration
# ============================================================================
verify_config() {
    print_step "Verifying configuration..."
    
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY-RUN] Skipping verification"
        return 0
    fi
    
    if [ ! -f "$MCP_JSON_FILE" ]; then
        print_error "Configuration file not found after creation"
        return 1
    fi
    
    # Check JSON validity
    if python3 -c "import json; json.load(open('$MCP_JSON_FILE'))" 2>/dev/null; then
        print_success "JSON syntax is valid"
    else
        print_error "JSON syntax is invalid"
        return 1
    fi
    
    # Check required fields
    local has_server=$(python3 -c "import json; c=json.load(open('$MCP_JSON_FILE')); print('ok' if 'ai-orchestrator' in c.get('mcpServers',{}) else 'missing')" 2>/dev/null)
    
    if [ "$has_server" = "ok" ]; then
        print_success "ai-orchestrator server configured"
    else
        print_error "ai-orchestrator server not found in config"
        return 1
    fi
    
    # Test Python path
    local cmd=$(python3 -c "import json; c=json.load(open('$MCP_JSON_FILE')); print(c['mcpServers']['ai-orchestrator']['command'])" 2>/dev/null)
    if [ -f "$cmd" ] || command -v "$cmd" &>/dev/null; then
        print_success "Python command is accessible"
    else
        print_warn "Python command might not be accessible: $cmd"
    fi
    
    return 0
}

# ============================================================================
# Print Instructions
# ============================================================================
print_instructions() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}                     ${WHITE}${BOLD}NEXT STEPS${NC}                         ${GREEN}║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${WHITE}To complete the setup:${NC}"
    echo ""
    echo -e "  ${CYAN}1.${NC} ${BOLD}Completely quit Cursor IDE${NC}"
    echo -e "     • On Mac: Press ${WHITE}Cmd+Q${NC} or right-click dock icon → Quit"
    echo -e "     • Make sure it's fully closed (not just minimized)"
    echo ""
    echo -e "  ${CYAN}2.${NC} ${BOLD}Reopen Cursor IDE${NC}"
    echo ""
    echo -e "  ${CYAN}3.${NC} ${BOLD}Verify MCP is loaded:${NC}"
    echo -e "     • Open Settings: ${WHITE}Cmd+,${NC} (Mac) or ${WHITE}Ctrl+,${NC} (Windows/Linux)"
    echo -e "     • Go to ${WHITE}Tools & Integrations${NC}"
    echo -e "     • Look for ${WHITE}MCP Tools${NC} section"
    echo -e "     • You should see ${GREEN}ai-orchestrator${NC} with a ${GREEN}green dot${NC}"
    echo ""
    echo -e "  ${CYAN}4.${NC} ${BOLD}Use MCP Tools:${NC}"
    echo -e "     • Open Chat panel (${WHITE}Cmd+L${NC} or ${WHITE}Ctrl+L${NC})"
    echo -e "     • Select ${WHITE}Agent${NC} mode (dropdown at top of chat)"
    echo -e "     • Type a prompt like: ${DIM}analyze this code${NC}"
    echo -e "     • The agent will automatically use MCP tools when needed"
    echo ""
    echo -e "  ${CYAN}5.${NC} ${BOLD}Check Available Tools:${NC}"
    echo -e "     • In Agent mode, click the ${WHITE}⚙️ (gear icon)${NC} or ${WHITE}Available Tools${NC}"
    echo -e "     • You should see ai-orchestrator tools listed"
    echo ""
    echo -e "  ${YELLOW}If tools don't appear:${NC}"
    echo -e "     • Run ${CYAN}./diagnose_cursor_mcp.sh${NC} to check for issues"
    echo -e "     • Check Cursor Output panel for MCP errors"
    echo -e "     • View MCP logs: ${WHITE}Cmd+Shift+P${NC} → 'Developer: Show Logs' → 'MCP Logs'"
    echo ""
}

# ============================================================================
# Main
# ============================================================================
main() {
    parse_args "$@"
    
    print_header
    
    if [ "$DRY_RUN" = true ]; then
        print_warn "Running in DRY-RUN mode - no changes will be made"
        echo ""
    fi
    
    # Step 1: Find installation directory
    print_step "Finding AI Orchestrator installation..."
    if ! find_install_dir; then
        print_error "Could not find AI Orchestrator installation"
        echo ""
        echo -e "  Please specify the installation directory:"
        echo -e "  ${CYAN}./fix_cursor_mcp.sh --install-dir /path/to/ai_orchestrator${NC}"
        exit 1
    fi
    print_success "Found installation at: $INSTALL_DIR"
    
    # Step 2: Check for old configurations
    print_step "Checking for deprecated configurations..."
    migrate_old_config
    
    # Step 3: Backup existing configuration
    print_step "Backing up existing configuration..."
    backup_existing
    
    # Step 4: Create new configuration
    print_step "Creating MCP configuration..."
    if ! create_mcp_config; then
        print_error "Failed to create configuration"
        exit 1
    fi
    
    # Step 5: Verify
    if ! verify_config; then
        print_error "Configuration verification failed"
        exit 1
    fi
    
    # Print instructions
    print_instructions
    
    echo -e "${GREEN}${BOLD}✅ Configuration complete!${NC}"
    echo ""
}

main "$@"
