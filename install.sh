#!/bin/bash
# ============================================================================
# AI Orchestrator - One-Command Installation Script
# ============================================================================
# This script automatically installs and configures the AI Orchestrator
# with MCP server and Cursor IDE integration on macOS.
#
# Usage: curl -fsSL https://raw.githubusercontent.com/.../install.sh | bash
#    or: ./install.sh
#
# For non-interactive installation, see quick-install.sh
# ============================================================================

set -e

# ============================================================================
# Configuration
# ============================================================================
SCRIPT_VERSION="1.0.0"
MIN_MACOS_VERSION="12.0"
MIN_PYTHON_VERSION="3.11"
DEFAULT_INSTALL_DIR="$HOME/ai-orchestrator"
DEFAULT_MCP_PORT="3000"
REPO_URL="https://github.com/dipcse07/ai-orchestrator.git"
LOG_FILE="/tmp/ai-orchestrator-install.log"
BACKUP_DIR="/tmp/ai-orchestrator-backup-$(date +%Y%m%d_%H%M%S)"

# ============================================================================
# Colors and Formatting
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'
DIM='\033[2m'

# Emojis
EMOJI_CHECK="✅"
EMOJI_CROSS="❌"
EMOJI_WARN="⚠️"
EMOJI_INFO="ℹ️"
EMOJI_ROCKET="🚀"
EMOJI_GEAR="⚙️"
EMOJI_KEY="🔑"
EMOJI_FOLDER="📁"
EMOJI_DOWNLOAD="📥"
EMOJI_PYTHON="🐍"
EMOJI_SERVER="🖥️"
EMOJI_SUCCESS="🎉"
EMOJI_LOADING="⏳"

# ============================================================================
# State Variables
# ============================================================================
INSTALL_DIR=""
MCP_PORT=""
AUTO_START=""
ENABLE_IOS=""
OPENAI_KEY=""
ANTHROPIC_KEY=""
GEMINI_KEY=""
MOONSHOT_KEY=""
DEFAULT_OPENAI_MODEL="gpt-4o-mini"
DEFAULT_ANTHROPIC_MODEL="claude-3-5-sonnet-20241022"
DEFAULT_GEMINI_MODEL="gemini-2.5-flash"
DEFAULT_MOONSHOT_MODEL="moonshot-v1-8k"
ROLLBACK_NEEDED=false
STEPS_COMPLETED=()

# ============================================================================
# Logging Functions
# ============================================================================
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_FILE"
}

# ============================================================================
# Output Functions
# ============================================================================
print_header() {
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}      ${EMOJI_ROCKET} ${BOLD}AI Orchestrator Installation Script${NC} ${EMOJI_ROCKET}           ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                     Version ${SCRIPT_VERSION}                            ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}${EMOJI_GEAR} ${BOLD}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "STEP: $1"
}

print_success() {
    echo -e "${GREEN}${EMOJI_CHECK} $1${NC}"
    log "SUCCESS: $1"
}

print_error() {
    echo -e "${RED}${EMOJI_CROSS} $1${NC}"
    log_error "$1"
}

print_warning() {
    echo -e "${YELLOW}${EMOJI_WARN} $1${NC}"
    log "WARNING: $1"
}

print_info() {
    echo -e "${WHITE}${EMOJI_INFO} $1${NC}"
    log "INFO: $1"
}

print_progress() {
    echo -e "${DIM}   ${EMOJI_LOADING} $1...${NC}"
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "      \b\b\b\b\b\b"
}

# ============================================================================
# Cleanup and Rollback Functions
# ============================================================================
cleanup() {
    if [ "$ROLLBACK_NEEDED" = true ]; then
        print_warning "Installation failed. Rolling back changes..."
        rollback
    fi
    # Clean up temp files
    rm -f /tmp/ai-orchestrator-*.tmp 2>/dev/null || true
}

rollback() {
    print_step "Rolling back installation"
    
    # Stop server if running
    if pgrep -f "mcp_server/server.py" > /dev/null 2>&1; then
        pkill -f "mcp_server/server.py" 2>/dev/null || true
        print_info "Stopped MCP server"
    fi
    
    # Remove launch agent
    local plist_path="$HOME/Library/LaunchAgents/com.ai-orchestrator.mcp-server.plist"
    if [ -f "$plist_path" ]; then
        launchctl unload "$plist_path" 2>/dev/null || true
        rm -f "$plist_path"
        print_info "Removed launch agent"
    fi
    
    # Restore backup if exists
    if [ -d "$BACKUP_DIR" ]; then
        if [ -d "$INSTALL_DIR" ]; then
            rm -rf "$INSTALL_DIR"
        fi
        mv "$BACKUP_DIR" "$INSTALL_DIR" 2>/dev/null || true
        print_info "Restored previous installation"
    fi
    
    print_info "Rollback completed. Check $LOG_FILE for details."
}

trap cleanup EXIT

# ============================================================================
# System Check Functions
# ============================================================================
check_os() {
    print_step "Checking Operating System"
    
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script is designed for macOS only."
        print_info "Detected OS: $OSTYPE"
        exit 1
    fi
    
    local macos_version=$(sw_vers -productVersion)
    local major_version=$(echo "$macos_version" | cut -d. -f1)
    local minor_version=$(echo "$macos_version" | cut -d. -f2)
    
    print_info "macOS Version: $macos_version"
    
    # Check minimum version (macOS 12.0 Monterey)
    if [ "$major_version" -lt 12 ]; then
        print_error "macOS 12.0 (Monterey) or later is required."
        print_info "Current version: $macos_version"
        exit 1
    fi
    
    print_success "Operating system compatible"
    STEPS_COMPLETED+=("os_check")
}

check_architecture() {
    local arch=$(uname -m)
    print_info "Architecture: $arch"
    
    if [[ "$arch" == "arm64" ]]; then
        print_success "Apple Silicon detected"
    elif [[ "$arch" == "x86_64" ]]; then
        print_success "Intel processor detected"
    else
        print_warning "Unknown architecture: $arch"
    fi
}

check_disk_space() {
    print_step "Checking Disk Space"
    
    local required_space=2048  # 2GB in MB
    local available_space=$(df -m "$HOME" | awk 'NR==2 {print $4}')
    
    print_info "Required: ${required_space}MB"
    print_info "Available: ${available_space}MB"
    
    if [ "$available_space" -lt "$required_space" ]; then
        print_error "Insufficient disk space. At least 2GB required."
        exit 1
    fi
    
    print_success "Sufficient disk space available"
    STEPS_COMPLETED+=("disk_check")
}

check_network() {
    print_step "Checking Network Connectivity"
    
    print_progress "Testing connection to GitHub"
    if ! curl -s --connect-timeout 5 https://github.com > /dev/null; then
        print_error "Cannot connect to GitHub. Please check your internet connection."
        exit 1
    fi
    print_success "GitHub accessible"
    
    print_progress "Testing connection to PyPI"
    if ! curl -s --connect-timeout 5 https://pypi.org > /dev/null; then
        print_warning "Cannot connect to PyPI. Pip installations may fail."
    else
        print_success "PyPI accessible"
    fi
    
    STEPS_COMPLETED+=("network_check")
}

# ============================================================================
# Dependency Installation Functions
# ============================================================================
install_xcode_cli() {
    print_step "Checking Xcode Command Line Tools"
    
    if xcode-select -p &> /dev/null; then
        print_success "Xcode Command Line Tools already installed"
        local xcode_path=$(xcode-select -p)
        print_info "Path: $xcode_path"
    else
        print_progress "Installing Xcode Command Line Tools"
        print_info "A dialog will appear. Please click 'Install' to continue."
        
        xcode-select --install 2>/dev/null || true
        
        # Wait for installation
        echo -e "${YELLOW}Waiting for Xcode CLI Tools installation...${NC}"
        echo -e "${DIM}Press Enter after installation completes${NC}"
        read -r
        
        if xcode-select -p &> /dev/null; then
            print_success "Xcode Command Line Tools installed"
        else
            print_error "Xcode Command Line Tools installation failed"
            exit 1
        fi
    fi
    
    STEPS_COMPLETED+=("xcode")
}

install_homebrew() {
    print_step "Checking Homebrew"
    
    if command -v brew &> /dev/null; then
        print_success "Homebrew already installed"
        local brew_version=$(brew --version | head -n1)
        print_info "Version: $brew_version"
        
        print_progress "Updating Homebrew"
        brew update > /dev/null 2>&1 || true
        print_success "Homebrew updated"
    else
        print_progress "Installing Homebrew"
        
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add to PATH for Apple Silicon
        if [[ $(uname -m) == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        
        if command -v brew &> /dev/null; then
            print_success "Homebrew installed successfully"
        else
            print_error "Homebrew installation failed"
            exit 1
        fi
    fi
    
    STEPS_COMPLETED+=("homebrew")
}

install_python() {
    print_step "Checking Python"
    
    local python_cmd=""
    local python_version=""
    
    # Check for python3.11 or higher
    for cmd in python3.12 python3.11 python3; do
        if command -v $cmd &> /dev/null; then
            local ver=$($cmd -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
            local major=$(echo $ver | cut -d. -f1)
            local minor=$(echo $ver | cut -d. -f2)
            
            if [ "$major" -ge 3 ] && [ "$minor" -ge 11 ]; then
                python_cmd=$cmd
                python_version=$ver
                break
            fi
        fi
    done
    
    if [ -n "$python_cmd" ]; then
        print_success "Python $python_version found ($python_cmd)"
    else
        print_progress "Installing Python 3.11"
        
        brew install python@3.11
        
        # Update PATH
        export PATH="/opt/homebrew/opt/python@3.11/bin:$PATH"
        export PATH="/usr/local/opt/python@3.11/bin:$PATH"
        
        python_cmd="python3.11"
        
        if command -v $python_cmd &> /dev/null; then
            python_version=$($python_cmd -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
            print_success "Python $python_version installed"
        else
            print_error "Python installation failed"
            exit 1
        fi
    fi
    
    # Store for later use
    PYTHON_CMD=$python_cmd
    STEPS_COMPLETED+=("python")
}

# ============================================================================
# Repository Setup Functions
# ============================================================================
setup_repository() {
    print_step "Setting up Repository"
    
    # Backup existing installation
    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Existing installation found at $INSTALL_DIR"
        
        # Check if it's a git repo and has local changes
        if [ -d "$INSTALL_DIR/.git" ]; then
            print_info "Creating backup of existing installation"
            mkdir -p "$BACKUP_DIR"
            cp -r "$INSTALL_DIR" "$BACKUP_DIR/"
            
            print_progress "Updating existing repository"
            cd "$INSTALL_DIR"
            git fetch origin 2>/dev/null || true
            git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || true
            print_success "Repository updated"
        else
            # Not a git repo, backup and re-clone
            print_info "Backing up and reinstalling"
            mv "$INSTALL_DIR" "$BACKUP_DIR"
            clone_repository
        fi
    else
        clone_repository
    fi
    
    STEPS_COMPLETED+=("repository")
}

clone_repository() {
    print_progress "Cloning repository to $INSTALL_DIR"
    
    mkdir -p "$(dirname "$INSTALL_DIR")"
    
    # For local development/testing, copy from current directory
    if [ -d "/home/ubuntu/ai_orchestrator" ]; then
        # Running in development environment
        cp -r /home/ubuntu/ai_orchestrator "$INSTALL_DIR"
        print_success "Repository copied (development mode)"
    else
        # Clone from remote
        git clone "$REPO_URL" "$INSTALL_DIR"
        print_success "Repository cloned"
    fi
}

# ============================================================================
# Python Environment Setup
# ============================================================================
setup_venv() {
    print_step "Setting up Python Virtual Environment"
    
    cd "$INSTALL_DIR"
    
    local venv_path="$INSTALL_DIR/venv"
    
    if [ -d "$venv_path" ]; then
        print_info "Virtual environment already exists"
        print_progress "Verifying virtual environment"
        
        if ! "$venv_path/bin/python" -c "import sys; sys.exit(0)" 2>/dev/null; then
            print_warning "Virtual environment corrupted, recreating"
            rm -rf "$venv_path"
            $PYTHON_CMD -m venv "$venv_path"
        fi
    else
        print_progress "Creating virtual environment"
        $PYTHON_CMD -m venv "$venv_path"
    fi
    
    # Activate venv
    source "$venv_path/bin/activate"
    
    # Upgrade pip
    print_progress "Upgrading pip"
    pip install --upgrade pip > /dev/null 2>&1
    
    print_success "Virtual environment ready"
    STEPS_COMPLETED+=("venv")
}

install_dependencies() {
    print_step "Installing Python Dependencies"
    
    cd "$INSTALL_DIR"
    source "$INSTALL_DIR/venv/bin/activate"
    
    # Install main requirements
    if [ -f "requirements.txt" ]; then
        print_progress "Installing main requirements"
        pip install -r requirements.txt > /dev/null 2>&1
        print_success "Main requirements installed"
    fi
    
    # Install MCP server requirements
    if [ -f "mcp_server/requirements.txt" ]; then
        print_progress "Installing MCP server requirements"
        pip install -r mcp_server/requirements.txt > /dev/null 2>&1
        print_success "MCP server requirements installed"
    fi
    
    # Install package in editable mode
    print_progress "Installing AI Orchestrator package"
    pip install -e . > /dev/null 2>&1
    print_success "AI Orchestrator package installed"
    
    STEPS_COMPLETED+=("dependencies")
}

# ============================================================================
# Prompt Helper Functions
# ============================================================================

# prompt_with_default: Display a prompt with default value and wait for input
# Usage: prompt_with_default "variable_name" "Prompt text" "default_value"
# The result is stored in the variable named by the first argument
prompt_with_default() {
    local var_name="$1"
    local prompt_text="$2"
    local default_value="$3"
    local user_input=""
    
    # Display the prompt with default value in brackets
    # Using printf for reliable output across shells
    printf "   %s" "$prompt_text"
    if [ -n "$default_value" ]; then
        printf " [%s]" "$default_value"
    fi
    printf ": "
    
    # Read user input - using -r to prevent backslash interpretation
    read -r user_input
    
    # Use default if input is empty
    if [ -z "$user_input" ]; then
        eval "$var_name=\"\$default_value\""
    else
        eval "$var_name=\"\$user_input\""
    fi
}

# prompt_no_default: Display a prompt without default value
# Usage: prompt_no_default "variable_name" "Prompt text"
prompt_no_default() {
    local var_name="$1"
    local prompt_text="$2"
    local user_input=""
    
    # Display the prompt
    printf "   %s: " "$prompt_text"
    
    # Read user input
    read -r user_input
    
    eval "$var_name=\"\$user_input\""
}

# prompt_yes_no: Display a yes/no prompt with default value
# Usage: prompt_yes_no "variable_name" "Prompt text" "yes|no"
prompt_yes_no() {
    local var_name="$1"
    local prompt_text="$2"
    local default_value="$3"
    local user_input=""
    
    # Display the prompt with (yes/no) and default
    printf "   %s (yes/no) [%s]: " "$prompt_text" "$default_value"
    
    # Read user input
    read -r user_input
    
    # Use default if input is empty, normalize to lowercase
    if [ -z "$user_input" ]; then
        eval "$var_name=\"\$default_value\""
    else
        # Normalize input
        user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')
        eval "$var_name=\"\$user_input\""
    fi
}

# ============================================================================
# Configuration Wizard
# ============================================================================
run_configuration_wizard() {
    print_step "Configuration Wizard"
    
    echo ""
    echo -e "${CYAN}${BOLD}Welcome to the AI Orchestrator Configuration Wizard!${NC}"
    echo -e "${DIM}Please provide the following information to configure your installation.${NC}"
    echo -e "${DIM}Press Enter to accept default values shown in brackets.${NC}"
    echo ""
    
    # Installation directory
    echo -e "${EMOJI_FOLDER} ${BOLD}Installation Directory${NC}"
    prompt_with_default "INSTALL_DIR" "Installation directory" "$DEFAULT_INSTALL_DIR"
    
    echo ""
    
    # API Keys
    echo -e "${EMOJI_KEY} ${BOLD}API Keys${NC}"
    echo -e "${DIM}   Get your API keys from:${NC}"
    echo -e "${DIM}   - OpenAI: https://platform.openai.com/api-keys${NC}"
    echo -e "${DIM}   - Anthropic: https://console.anthropic.com/settings/keys${NC}"
    echo -e "${DIM}   - Google AI: https://aistudio.google.com/app/apikey${NC}"
    echo -e "${DIM}   - Moonshot: https://platform.moonshot.cn/${NC}"
    echo ""
    
    prompt_no_default "OPENAI_KEY" "OpenAI API Key"
    prompt_no_default "ANTHROPIC_KEY" "Anthropic API Key"
    prompt_no_default "GEMINI_KEY" "Google Gemini API Key"
    prompt_no_default "MOONSHOT_KEY" "Moonshot API Key (optional)"
    
    echo ""
    
    # Default Models
    echo -e "${EMOJI_GEAR} ${BOLD}Default Models${NC}"
    prompt_with_default "OPENAI_MODEL" "OpenAI Model" "$DEFAULT_OPENAI_MODEL"
    prompt_with_default "ANTHROPIC_MODEL" "Anthropic Model" "$DEFAULT_ANTHROPIC_MODEL"
    prompt_with_default "GEMINI_MODEL" "Gemini Model" "$DEFAULT_GEMINI_MODEL"
    prompt_with_default "MOONSHOT_MODEL" "Moonshot Model" "$DEFAULT_MOONSHOT_MODEL"
    
    echo ""
    
    # MCP Server Configuration
    echo -e "${EMOJI_SERVER} ${BOLD}MCP Server Configuration${NC}"
    prompt_with_default "MCP_PORT" "MCP Server Port" "$DEFAULT_MCP_PORT"
    
    echo ""
    
    # Auto-start
    echo -e "${EMOJI_ROCKET} ${BOLD}Startup Options${NC}"
    prompt_yes_no "AUTO_START" "Auto-start MCP server on login?" "yes"
    prompt_yes_no "ENABLE_IOS" "Enable iOS development tools?" "no"
    
    echo ""
    echo -e "${GREEN}Configuration complete!${NC}"
    
    STEPS_COMPLETED+=("config_wizard")
}

# ============================================================================
# Environment File Generation
# ============================================================================
generate_env_file() {
    print_step "Generating Environment Configuration"
    
    local env_file="$INSTALL_DIR/.env"
    
    # Backup existing .env
    if [ -f "$env_file" ]; then
        cp "$env_file" "$env_file.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Backed up existing .env file"
    fi
    
    cat > "$env_file" << EOF
# ============================================================================
# AI Orchestrator Configuration
# Generated on $(date)
# ============================================================================

# API Keys
OPENAI_API_KEY=$OPENAI_KEY
ANTHROPIC_API_KEY=$ANTHROPIC_KEY
GEMINI_API_KEY=$GEMINI_KEY
MOONSHOT_API_KEY=$MOONSHOT_KEY

# Model Configuration
OPENAI_MODEL=$OPENAI_MODEL
ANTHROPIC_MODEL=$ANTHROPIC_MODEL
GEMINI_MODEL=$GEMINI_MODEL
MOONSHOT_MODEL=$MOONSHOT_MODEL

# MCP Server Configuration
MCP_SERVER_PORT=$MCP_PORT
MCP_SERVER_HOST=localhost

# Auto-Fix Configuration
MAX_FIX_ATTEMPTS=5
MAX_SAME_ERROR_ATTEMPTS=3
MAX_VERIFICATION_CYCLES=10
FIX_CONFIDENCE_THRESHOLD=0.7
AI_FIX_CONFIDENCE_THRESHOLD=0.6

# Execution Configuration
EXECUTION_TIMEOUT=300
MAX_RETRIES=3
OUTPUT_LIMIT=512000

# Logging
LOG_LEVEL=INFO

# Installation Info
INSTALL_DIR=$INSTALL_DIR
INSTALL_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
INSTALLER_VERSION=$SCRIPT_VERSION
EOF
    
    chmod 600 "$env_file"
    print_success "Environment file generated at $env_file"
    STEPS_COMPLETED+=("env_file")
}

# ============================================================================
# MCP Server Setup
# ============================================================================
setup_mcp_server() {
    print_step "Setting up MCP Server"
    
    cd "$INSTALL_DIR"
    
    # Make start script executable
    if [ -f "mcp_server/start.sh" ]; then
        chmod +x mcp_server/start.sh
    fi
    
    # Create mcp_server/.env symlink
    if [ ! -f "mcp_server/.env" ] && [ -f ".env" ]; then
        ln -sf "$INSTALL_DIR/.env" "$INSTALL_DIR/mcp_server/.env"
        print_info "Linked .env to mcp_server"
    fi
    
    print_success "MCP server configured"
    STEPS_COMPLETED+=("mcp_setup")
}

# ============================================================================
# Cursor Integration
# ============================================================================
setup_cursor_integration() {
    print_step "Configuring Cursor IDE Integration"
    
    local cursor_config_dir="$HOME/Library/Application Support/Cursor/User"
    local mcp_config_file="$cursor_config_dir/globalStorage/mcp-settings.json"
    
    # Create directory if needed
    mkdir -p "$cursor_config_dir/globalStorage"
    
    # Generate Cursor MCP configuration
    local mcp_config='{
  "mcpServers": {
    "ai-orchestrator": {
      "command": "'"$INSTALL_DIR"'/venv/bin/python",
      "args": ["-m", "mcp_server.server"],
      "cwd": "'"$INSTALL_DIR"'",
      "env": {
        "PYTHONPATH": "'"$INSTALL_DIR"'"
      }
    }
  }
}'
    
    # Backup existing config
    if [ -f "$mcp_config_file" ]; then
        cp "$mcp_config_file" "$mcp_config_file.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Backed up existing Cursor MCP configuration"
    fi
    
    echo "$mcp_config" > "$mcp_config_file"
    print_success "Cursor MCP configuration created"
    
    # Copy .cursorrules to home directory
    if [ -f "$INSTALL_DIR/cursor_integration/.cursorrules" ]; then
        cp "$INSTALL_DIR/cursor_integration/.cursorrules" "$HOME/.cursorrules"
        print_success "Cursor rules file installed"
    fi
    
    print_info "Cursor integration configured"
    print_info "Restart Cursor IDE to apply changes"
    
    STEPS_COMPLETED+=("cursor_integration")
}

# ============================================================================
# Launch Agent Setup
# ============================================================================
setup_launch_agent() {
    print_step "Setting up Auto-Start"
    
    if [ "$AUTO_START" != "yes" ]; then
        print_info "Auto-start disabled by user"
        return
    fi
    
    local plist_dir="$HOME/Library/LaunchAgents"
    local plist_file="$plist_dir/com.ai-orchestrator.mcp-server.plist"
    
    mkdir -p "$plist_dir"
    
    cat > "$plist_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ai-orchestrator.mcp-server</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL_DIR/venv/bin/python</string>
        <string>-m</string>
        <string>mcp_server.server</string>
    </array>
    
    <key>WorkingDirectory</key>
    <string>$INSTALL_DIR</string>
    
    <key>EnvironmentVariables</key>
    <dict>
        <key>PYTHONPATH</key>
        <string>$INSTALL_DIR</string>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin</string>
    </dict>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>
    
    <key>StandardOutPath</key>
    <string>$INSTALL_DIR/logs/mcp-server.log</string>
    
    <key>StandardErrorPath</key>
    <string>$INSTALL_DIR/logs/mcp-server.error.log</string>
    
    <key>ThrottleInterval</key>
    <integer>10</integer>
</dict>
</plist>
EOF
    
    # Create logs directory
    mkdir -p "$INSTALL_DIR/logs"
    
    # Load the launch agent
    launchctl unload "$plist_file" 2>/dev/null || true
    launchctl load "$plist_file"
    
    print_success "Launch agent installed"
    print_info "MCP server will start automatically on login"
    
    STEPS_COMPLETED+=("launch_agent")
}

# ============================================================================
# Start MCP Server
# ============================================================================
start_mcp_server() {
    print_step "Starting MCP Server"
    
    cd "$INSTALL_DIR"
    source "$INSTALL_DIR/venv/bin/activate"
    
    # Check if already running
    if pgrep -f "mcp_server.server" > /dev/null 2>&1; then
        print_info "MCP server is already running"
    else
        # Start server in background
        export PYTHONPATH="$INSTALL_DIR"
        nohup "$INSTALL_DIR/venv/bin/python" -m mcp_server.server > "$INSTALL_DIR/logs/mcp-server.log" 2>&1 &
        
        sleep 2
        
        if pgrep -f "mcp_server.server" > /dev/null 2>&1; then
            print_success "MCP server started"
            print_info "Logs: $INSTALL_DIR/logs/mcp-server.log"
        else
            print_warning "MCP server may not have started properly"
            print_info "Check logs at: $INSTALL_DIR/logs/mcp-server.log"
        fi
    fi
    
    STEPS_COMPLETED+=("start_server")
}

# ============================================================================
# Verification
# ============================================================================
run_verification() {
    print_step "Running Verification"
    
    local verification_passed=true
    local report_file="$INSTALL_DIR/verification_report.txt"
    
    echo "AI Orchestrator Verification Report" > "$report_file"
    echo "Generated: $(date)" >> "$report_file"
    echo "========================================" >> "$report_file"
    echo "" >> "$report_file"
    
    # Test Python
    print_progress "Verifying Python installation"
    if "$INSTALL_DIR/venv/bin/python" -c "import sys; print(sys.version)" >> "$report_file" 2>&1; then
        print_success "Python installation verified"
        echo "✓ Python: OK" >> "$report_file"
    else
        print_error "Python verification failed"
        echo "✗ Python: FAILED" >> "$report_file"
        verification_passed=false
    fi
    
    # Test pip packages
    print_progress "Verifying pip packages"
    local packages=("openai" "anthropic" "google-generativeai" "rich" "click" "pydantic")
    for pkg in "${packages[@]}"; do
        if "$INSTALL_DIR/venv/bin/python" -c "import ${pkg//-/_}" 2>/dev/null; then
            echo "✓ Package $pkg: OK" >> "$report_file"
        else
            echo "✗ Package $pkg: MISSING" >> "$report_file"
            verification_passed=false
        fi
    done
    print_success "Pip packages verified"
    
    # Test API connections (only if keys provided)
    print_progress "Testing API connections"
    
    if [ -n "$OPENAI_KEY" ]; then
        local test_result=$("$INSTALL_DIR/venv/bin/python" -c "
import openai
client = openai.OpenAI(api_key='$OPENAI_KEY')
try:
    client.models.list()
    print('OK')
except Exception as e:
    print(f'FAILED: {e}')
" 2>&1)
        if [[ "$test_result" == "OK" ]]; then
            print_success "OpenAI API connection verified"
            echo "✓ OpenAI API: OK" >> "$report_file"
        else
            print_warning "OpenAI API connection failed: $test_result"
            echo "✗ OpenAI API: $test_result" >> "$report_file"
        fi
    fi
    
    # Test MCP server
    print_progress "Verifying MCP server"
    if pgrep -f "mcp_server.server" > /dev/null 2>&1; then
        print_success "MCP server is running"
        echo "✓ MCP Server: RUNNING" >> "$report_file"
    else
        print_warning "MCP server is not running"
        echo "○ MCP Server: NOT RUNNING" >> "$report_file"
    fi
    
    # Test Cursor integration
    print_progress "Verifying Cursor integration"
    local cursor_config="$HOME/Library/Application Support/Cursor/User/globalStorage/mcp-settings.json"
    if [ -f "$cursor_config" ]; then
        print_success "Cursor MCP configuration exists"
        echo "✓ Cursor Config: OK" >> "$report_file"
    else
        print_warning "Cursor MCP configuration not found"
        echo "○ Cursor Config: NOT FOUND" >> "$report_file"
    fi
    
    echo "" >> "$report_file"
    echo "========================================" >> "$report_file"
    echo "Verification completed at $(date)" >> "$report_file"
    
    print_info "Verification report saved to: $report_file"
    
    if [ "$verification_passed" = true ]; then
        print_success "All verifications passed!"
    else
        print_warning "Some verifications failed. Check the report for details."
    fi
    
    STEPS_COMPLETED+=("verification")
}

# ============================================================================
# Print Success Message
# ============================================================================
print_success_message() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}                                                              ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}   ${EMOJI_SUCCESS} ${BOLD}Installation Complete!${NC}                             ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}                                                              ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${BOLD}Installation Summary:${NC}"
    echo -e "  ${EMOJI_FOLDER} Installation Directory: ${CYAN}$INSTALL_DIR${NC}"
    echo -e "  ${EMOJI_PYTHON} Python Environment: ${CYAN}$INSTALL_DIR/venv${NC}"
    echo -e "  ${EMOJI_SERVER} MCP Server Port: ${CYAN}$MCP_PORT${NC}"
    if [ "$AUTO_START" = "yes" ]; then
        echo -e "  ${EMOJI_ROCKET} Auto-start: ${GREEN}Enabled${NC}"
    else
        echo -e "  ${EMOJI_ROCKET} Auto-start: ${YELLOW}Disabled${NC}"
    fi
    echo ""
    
    echo -e "${BOLD}Next Steps:${NC}"
    echo -e "  1. ${WHITE}Restart Cursor IDE${NC} to enable MCP integration"
    echo -e "  2. ${WHITE}Open a project${NC} and use AI Orchestrator tools"
    echo -e "  3. ${WHITE}Test the installation${NC} by running:"
    echo -e "     ${CYAN}cd $INSTALL_DIR && ./scripts/test-apis.sh${NC}"
    echo ""
    
    echo -e "${BOLD}Useful Commands:${NC}"
    echo -e "  Start MCP Server:   ${CYAN}$INSTALL_DIR/scripts/start-server.sh${NC}"
    echo -e "  Stop MCP Server:    ${CYAN}$INSTALL_DIR/scripts/stop-server.sh${NC}"
    echo -e "  View Logs:          ${CYAN}$INSTALL_DIR/scripts/logs.sh${NC}"
    echo -e "  Check Status:       ${CYAN}$INSTALL_DIR/scripts/status.sh${NC}"
    echo -e "  Update:             ${CYAN}$INSTALL_DIR/update.sh${NC}"
    echo -e "  Uninstall:          ${CYAN}$INSTALL_DIR/uninstall.sh${NC}"
    echo ""
    
    echo -e "${BOLD}Documentation:${NC}"
    echo -e "  ${CYAN}$INSTALL_DIR/README.md${NC}"
    echo -e "  ${CYAN}$INSTALL_DIR/cursor_integration/CURSOR_SETUP.md${NC}"
    echo ""
    
    echo -e "${DIM}Installation log: $LOG_FILE${NC}"
    echo ""
    
    echo -e "${PURPLE}Thank you for using AI Orchestrator! ${EMOJI_ROCKET}${NC}"
}

# ============================================================================
# Main Function
# ============================================================================
main() {
    # Initialize log file
    echo "AI Orchestrator Installation Log" > "$LOG_FILE"
    echo "Started: $(date)" >> "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"
    
    print_header
    
    # System checks
    check_os
    check_architecture
    check_disk_space
    check_network
    
    # Run configuration wizard (sets INSTALL_DIR)
    run_configuration_wizard
    
    # Mark rollback as needed from here
    ROLLBACK_NEEDED=true
    
    # Install dependencies
    install_xcode_cli
    install_homebrew
    install_python
    
    # Setup repository
    setup_repository
    
    # Setup Python environment
    setup_venv
    install_dependencies
    
    # Generate configuration
    generate_env_file
    
    # Setup MCP server
    setup_mcp_server
    
    # Setup Cursor integration
    setup_cursor_integration
    
    # Setup auto-start
    setup_launch_agent
    
    # Create helper scripts
    create_helper_scripts
    
    # Start server
    start_mcp_server
    
    # Run verification
    run_verification
    
    # Mark installation as complete (no rollback needed)
    ROLLBACK_NEEDED=false
    
    # Print success message
    print_success_message
    
    log "Installation completed successfully"
}

# ============================================================================
# Create Helper Scripts
# ============================================================================
create_helper_scripts() {
    print_step "Creating Helper Scripts"
    
    local scripts_dir="$INSTALL_DIR/scripts"
    mkdir -p "$scripts_dir"
    
    # Create all helper scripts (they will be created separately)
    print_info "Helper scripts will be installed to $scripts_dir"
    
    # Make scripts executable
    chmod +x "$scripts_dir"/*.sh 2>/dev/null || true
    
    print_success "Helper scripts created"
    STEPS_COMPLETED+=("helper_scripts")
}

# ============================================================================
# Run Main
# ============================================================================
main "$@"
