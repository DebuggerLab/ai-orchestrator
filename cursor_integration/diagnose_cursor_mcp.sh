#!/bin/bash
# ============================================================================
# Cursor MCP Diagnostic Script
# ============================================================================
# This script diagnoses issues with Cursor IDE MCP integration.
# It checks configuration files, paths, and provides actionable fixes.
#
# Usage: ./diagnose_cursor_mcp.sh
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

# Emojis
CHECK="✅"
CROSS="❌"
WARN="⚠️"
INFO="ℹ️"

# Results tracking
ISSUES_FOUND=0
declare -a ISSUES
declare -a FIXES

# ============================================================================
# Helper Functions
# ============================================================================
print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}       ${WHITE}${BOLD}Cursor MCP Integration Diagnostic Tool${NC}       ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}${BOLD}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_check() {
    echo -e "  ${GREEN}${CHECK}${NC} $1"
}

print_fail() {
    echo -e "  ${RED}${CROSS}${NC} $1"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
}

print_warn() {
    echo -e "  ${YELLOW}${WARN}${NC} $1"
}

print_info() {
    echo -e "  ${BLUE}${INFO}${NC} $1"
}

add_issue() {
    ISSUES+=("$1")
}

add_fix() {
    FIXES+=("$1")
}

# ============================================================================
# Detect Operating System
# ============================================================================
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macOS"
        CURSOR_CONFIG_DIR="$HOME/.cursor"
        CURSOR_APP_DIR="/Applications/Cursor.app"
        # Alternative locations for Cursor on macOS
        CURSOR_ALT_CONFIG="$HOME/Library/Application Support/Cursor/User"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="Linux"
        CURSOR_CONFIG_DIR="$HOME/.cursor"
        CURSOR_APP_DIR=""
    else
        OS="Windows"
        CURSOR_CONFIG_DIR="$USERPROFILE/.cursor"
    fi
}

# ============================================================================
# Check 1: Cursor Installation
# ============================================================================
check_cursor_installed() {
    print_section "1. Checking Cursor IDE Installation"
    
    # Check if Cursor is installed
    if [[ "$OS" == "macOS" ]]; then
        if [ -d "$CURSOR_APP_DIR" ]; then
            print_check "Cursor IDE is installed at $CURSOR_APP_DIR"
            
            # Try to get version
            local plist="$CURSOR_APP_DIR/Contents/Info.plist"
            if [ -f "$plist" ]; then
                local version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$plist" 2>/dev/null || echo "Unknown")
                print_info "Cursor version: $version"
                
                # Check if version supports MCP (0.40.0+)
                if [[ "$version" != "Unknown" ]]; then
                    local major_version=$(echo "$version" | cut -d'.' -f1)
                    local minor_version=$(echo "$version" | cut -d'.' -f2)
                    if [[ $major_version -gt 0 ]] || [[ $major_version -eq 0 && $minor_version -ge 40 ]]; then
                        print_check "Version supports MCP (requires 0.40.0+)"
                    else
                        print_warn "Version may not support MCP. Requires 0.40.0+. Please update Cursor."
                        add_issue "Cursor version $version may not support MCP"
                        add_fix "Update Cursor to version 0.40.0 or later"
                    fi
                fi
            fi
        else
            print_fail "Cursor IDE not found at $CURSOR_APP_DIR"
            add_issue "Cursor IDE is not installed"
            add_fix "Install Cursor IDE from https://cursor.sh"
            return 1
        fi
    elif command -v cursor &>/dev/null; then
        print_check "Cursor command found in PATH"
    else
        print_warn "Could not verify Cursor installation"
        print_info "Please ensure Cursor IDE is installed"
    fi
    
    return 0
}

# ============================================================================
# Check 2: MCP Configuration File
# ============================================================================
check_mcp_config() {
    print_section "2. Checking MCP Configuration Files"
    
    local mcp_json="$CURSOR_CONFIG_DIR/mcp.json"
    local old_mcp_settings="$HOME/Library/Application Support/Cursor/User/globalStorage/mcp-settings.json"
    
    # Check for correct mcp.json location
    echo -e "\n  ${WHITE}Checking correct location:${NC} $mcp_json"
    
    if [ -f "$mcp_json" ]; then
        print_check "mcp.json exists at correct location"
        
        # Check if it's valid JSON
        if python3 -c "import json; json.load(open('$mcp_json'))" 2>/dev/null; then
            print_check "mcp.json is valid JSON"
            
            # Check for ai-orchestrator entry
            if grep -q "ai-orchestrator" "$mcp_json" 2>/dev/null; then
                print_check "ai-orchestrator entry found in mcp.json"
            else
                print_fail "ai-orchestrator NOT found in mcp.json"
                add_issue "mcp.json exists but doesn't have ai-orchestrator configuration"
                add_fix "Run ./fix_cursor_mcp.sh to add the correct configuration"
            fi
        else
            print_fail "mcp.json is NOT valid JSON"
            add_issue "mcp.json file contains invalid JSON"
            add_fix "Run ./fix_cursor_mcp.sh to recreate the configuration"
        fi
    else
        print_fail "mcp.json NOT found at correct location"
        add_issue "mcp.json file does not exist at ~/.cursor/mcp.json"
        add_fix "Run ./fix_cursor_mcp.sh to create the configuration"
    fi
    
    # Check for OLD/WRONG location
    echo -e "\n  ${WHITE}Checking for OLD location (deprecated):${NC}"
    if [ -f "$old_mcp_settings" ]; then
        print_warn "Found OLD mcp-settings.json at deprecated location"
        print_info "Location: $old_mcp_settings"
        print_info "This location is NO LONGER used by Cursor"
        add_issue "Configuration exists at deprecated location"
        add_fix "The fix script will migrate settings to the correct location"
    else
        print_info "No deprecated configuration found (good)"
    fi
    
    # Check .cursor directory exists
    if [ ! -d "$CURSOR_CONFIG_DIR" ]; then
        print_warn "$CURSOR_CONFIG_DIR directory does not exist"
        add_issue "~/.cursor directory does not exist"
        add_fix "The fix script will create the directory"
    fi
}

# ============================================================================
# Check 3: AI Orchestrator Installation
# ============================================================================
check_orchestrator_installation() {
    print_section "3. Checking AI Orchestrator Installation"
    
    # Find installation directory
    local install_dir=""
    local possible_dirs=(
        "$HOME/ai-orchestrator"
        "$HOME/ai_orchestrator"
        "/home/ubuntu/ai_orchestrator"
        "$(dirname "$(dirname "$0")")"
    )
    
    for dir in "${possible_dirs[@]}"; do
        if [ -f "$dir/mcp_server/server.py" ]; then
            install_dir="$dir"
            break
        fi
    done
    
    if [ -n "$install_dir" ]; then
        print_check "AI Orchestrator found at: $install_dir"
        export AI_ORCHESTRATOR_DIR="$install_dir"
        
        # Check server.py exists
        if [ -f "$install_dir/mcp_server/server.py" ]; then
            print_check "MCP server script exists"
        else
            print_fail "MCP server script NOT found"
            add_issue "server.py not found in mcp_server directory"
        fi
        
        # Check virtual environment
        if [ -d "$install_dir/venv" ]; then
            print_check "Python virtual environment exists"
            
            # Check Python in venv
            if [ -f "$install_dir/venv/bin/python" ] || [ -f "$install_dir/venv/bin/python3" ]; then
                print_check "Python executable in venv"
            else
                print_fail "Python executable NOT found in venv"
                add_issue "Virtual environment exists but Python not found"
                add_fix "Recreate virtual environment: python3 -m venv venv"
            fi
        else
            print_warn "No virtual environment found"
            print_info "Using system Python (may work but venv recommended)"
        fi
        
        # Check .env file
        if [ -f "$install_dir/.env" ]; then
            print_check ".env file exists"
            
            # Check for required API keys
            if grep -q "OPENAI_API_KEY" "$install_dir/.env" 2>/dev/null; then
                print_check "OPENAI_API_KEY configured"
            else
                print_warn "OPENAI_API_KEY not found in .env"
            fi
            
            if grep -q "ANTHROPIC_API_KEY" "$install_dir/.env" 2>/dev/null; then
                print_check "ANTHROPIC_API_KEY configured"
            else
                print_warn "ANTHROPIC_API_KEY not found in .env"
            fi
        else
            print_fail ".env file NOT found"
            add_issue ".env file does not exist"
            add_fix "Copy .env.example to .env and add your API keys"
        fi
    else
        print_fail "AI Orchestrator installation NOT found"
        add_issue "Could not locate AI Orchestrator installation"
        add_fix "Install AI Orchestrator first or specify the correct path"
        export AI_ORCHESTRATOR_DIR=""
    fi
}

# ============================================================================
# Check 4: Python Environment
# ============================================================================
check_python_environment() {
    print_section "4. Checking Python Environment"
    
    # Check system Python
    if command -v python3 &>/dev/null; then
        local py_version=$(python3 --version 2>&1)
        print_check "System Python: $py_version"
    else
        print_fail "Python3 not found in PATH"
        add_issue "Python3 is not installed or not in PATH"
        add_fix "Install Python 3.9+ from python.org or via Homebrew"
    fi
    
    # Check venv Python if available
    if [ -n "$AI_ORCHESTRATOR_DIR" ] && [ -f "$AI_ORCHESTRATOR_DIR/venv/bin/python" ]; then
        local venv_version=$("$AI_ORCHESTRATOR_DIR/venv/bin/python" --version 2>&1)
        print_check "Venv Python: $venv_version"
    fi
    
    # Check required packages
    echo -e "\n  ${WHITE}Checking required packages:${NC}"
    
    local python_cmd="python3"
    if [ -n "$AI_ORCHESTRATOR_DIR" ] && [ -f "$AI_ORCHESTRATOR_DIR/venv/bin/python" ]; then
        python_cmd="$AI_ORCHESTRATOR_DIR/venv/bin/python"
    fi
    
    local packages=("mcp" "openai" "anthropic" "rich" "click" "pydantic")
    for pkg in "${packages[@]}"; do
        if $python_cmd -c "import $pkg" 2>/dev/null; then
            print_check "$pkg installed"
        else
            print_fail "$pkg NOT installed"
            add_issue "Required package '$pkg' is not installed"
            add_fix "pip install $pkg"
        fi
    done
}

# ============================================================================
# Check 5: MCP Server Test
# ============================================================================
check_mcp_server() {
    print_section "5. Testing MCP Server"
    
    if [ -z "$AI_ORCHESTRATOR_DIR" ]; then
        print_warn "Skipping - AI Orchestrator not found"
        return
    fi
    
    local server_py="$AI_ORCHESTRATOR_DIR/mcp_server/server.py"
    
    if [ ! -f "$server_py" ]; then
        print_fail "server.py not found"
        return
    fi
    
    # Check if server can be imported without errors
    local python_cmd="python3"
    if [ -f "$AI_ORCHESTRATOR_DIR/venv/bin/python" ]; then
        python_cmd="$AI_ORCHESTRATOR_DIR/venv/bin/python"
    fi
    
    print_info "Testing server import..."
    
    cd "$AI_ORCHESTRATOR_DIR"
    export PYTHONPATH="$AI_ORCHESTRATOR_DIR:$PYTHONPATH"
    
    if $python_cmd -c "import mcp_server.server" 2>/dev/null; then
        print_check "Server module imports successfully"
    else
        print_fail "Server module import failed"
        print_info "Running detailed import test..."
        $python_cmd -c "import mcp_server.server" 2>&1 | head -5 || true
        add_issue "MCP server has import errors"
        add_fix "Check Python dependencies and paths"
    fi
}

# ============================================================================
# Check 6: Verify MCP.json Content
# ============================================================================
check_mcp_json_content() {
    print_section "6. Verifying MCP.json Configuration"
    
    local mcp_json="$CURSOR_CONFIG_DIR/mcp.json"
    
    if [ ! -f "$mcp_json" ]; then
        print_warn "mcp.json not found - skipping content check"
        return
    fi
    
    echo -e "\n  ${WHITE}Current mcp.json content:${NC}"
    echo -e "${CYAN}  ─────────────────────────────────────────────────${NC}"
    cat "$mcp_json" | while IFS= read -r line; do
        echo -e "  ${DIM}$line${NC}"
    done
    echo -e "${CYAN}  ─────────────────────────────────────────────────${NC}"
    
    # Check command path
    local cmd_path=$(python3 -c "import json; c=json.load(open('$mcp_json')); print(c.get('mcpServers',{}).get('ai-orchestrator',{}).get('command',''))" 2>/dev/null || echo "")
    
    if [ -n "$cmd_path" ]; then
        if [ -f "$cmd_path" ]; then
            print_check "Python command path exists: $cmd_path"
        else
            print_fail "Python command path NOT found: $cmd_path"
            add_issue "Configured Python path does not exist: $cmd_path"
            add_fix "Run ./fix_cursor_mcp.sh to fix the path"
        fi
    fi
    
    # Check cwd/working directory
    local cwd_path=$(python3 -c "import json; c=json.load(open('$mcp_json')); print(c.get('mcpServers',{}).get('ai-orchestrator',{}).get('cwd',''))" 2>/dev/null || echo "")
    
    if [ -n "$cwd_path" ]; then
        if [ -d "$cwd_path" ]; then
            print_check "Working directory exists: $cwd_path"
        else
            print_fail "Working directory NOT found: $cwd_path"
            add_issue "Configured working directory does not exist: $cwd_path"
            add_fix "Run ./fix_cursor_mcp.sh to fix the path"
        fi
    fi
}

# ============================================================================
# Summary
# ============================================================================
print_summary() {
    print_section "Diagnostic Summary"
    
    if [ ${#ISSUES[@]} -eq 0 ]; then
        echo ""
        echo -e "  ${GREEN}${BOLD}✨ All checks passed!${NC}"
        echo ""
        echo -e "  ${WHITE}If MCP tools still don't appear in Cursor:${NC}"
        echo -e "  1. Completely quit Cursor (Cmd+Q on Mac)"
        echo -e "  2. Reopen Cursor"
        echo -e "  3. Open Settings (Cmd+,) → Tools & Integrations → MCP Tools"
        echo -e "  4. Look for a green dot next to ai-orchestrator"
        echo -e "  5. In chat, use Agent mode to see available tools"
        echo ""
    else
        echo ""
        echo -e "  ${RED}${BOLD}Found ${#ISSUES[@]} issue(s):${NC}"
        echo ""
        
        local i=1
        for issue in "${ISSUES[@]}"; do
            echo -e "  ${RED}$i.${NC} $issue"
            i=$((i + 1))
        done
        
        echo ""
        echo -e "  ${YELLOW}${BOLD}Recommended fixes:${NC}"
        echo ""
        
        i=1
        for fix in "${FIXES[@]}"; do
            echo -e "  ${GREEN}$i.${NC} $fix"
            i=$((i + 1))
        done
        
        echo ""
        echo -e "  ${WHITE}Quick fix:${NC} Run ${CYAN}./fix_cursor_mcp.sh${NC} to automatically fix these issues"
        echo ""
    fi
}

# ============================================================================
# Main
# ============================================================================
main() {
    print_header
    
    detect_os
    print_info "Detected OS: $OS"
    print_info "Cursor config directory: $CURSOR_CONFIG_DIR"
    
    check_cursor_installed
    check_mcp_config
    check_orchestrator_installation
    check_python_environment
    check_mcp_server
    check_mcp_json_content
    
    print_summary
}

main "$@"
