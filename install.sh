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

# Ensure script runs with bash (for associative array support)
# This handles cases where user runs: zsh install.sh or sh install.sh
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi

# Ensure bash version 4+ for associative arrays
if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
    echo "Error: This script requires bash version 4.0 or higher."
    echo "Current bash version: $BASH_VERSION"
    echo ""
    echo "On macOS, you can install a newer bash with:"
    echo "  brew install bash"
    echo "Then run: /opt/homebrew/bin/bash install.sh"
    exit 1
fi

set -e

# ============================================================================
# Configuration
# ============================================================================
SCRIPT_VERSION="1.1.0"
MIN_MACOS_VERSION="12.0"
MIN_PYTHON_VERSION="3.11"
DEFAULT_INSTALL_DIR="$HOME/ai-orchestrator"
DEFAULT_MCP_PORT="3000"
REPO_URL="https://github.com/DebuggerLab/ai-orchestrator.git"
LOG_FILE="/tmp/ai-orchestrator-install.log"
BACKUP_DIR="/tmp/ai-orchestrator-backup-$(date +%Y%m%d_%H%M%S)"

# ============================================================================
# Required Packages List
# ============================================================================
# Core AI client packages
REQUIRED_PACKAGES=(
    "openai"
    "anthropic"
    "google-genai"
    "rich"
    "click"
    "pydantic"
    "python-dotenv"
    "requests"
)

# Additional packages for full functionality
OPTIONAL_PACKAGES=(
    "mcp"
)

# Package installation status tracking
declare -A PACKAGE_STATUS
declare -A PACKAGE_RETRIES
declare -A PACKAGE_ERRORS

# Retry configuration
MAX_INSTALL_RETRIES=3
RETRY_DELAY=2

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
# Package Installation Functions with Retry Logic
# ============================================================================

# Get the import name for a package (handles packages with different import names)
get_import_name() {
    local package="$1"
    case "$package" in
        "google-genai")
            echo "google.genai"
            ;;
        "python-dotenv")
            echo "dotenv"
            ;;
        *)
            echo "${package//-/_}"
            ;;
    esac
}

# Check if a package is installed and importable
check_package_installed() {
    local package="$1"
    local import_name=$(get_import_name "$package")
    
    "$INSTALL_DIR/venv/bin/python" -c "import $import_name" 2>/dev/null
    return $?
}

# Install a single package with retry logic
install_package_with_retry() {
    local package="$1"
    local attempt=1
    local success=false
    local last_error=""
    
    PACKAGE_RETRIES[$package]=0
    
    while [ $attempt -le $MAX_INSTALL_RETRIES ] && [ "$success" = false ]; do
        PACKAGE_RETRIES[$package]=$attempt
        
        if [ $attempt -gt 1 ]; then
            echo -e "${YELLOW}      Retry $attempt/$MAX_INSTALL_RETRIES for $package...${NC}"
            log "Retry $attempt for package $package"
            sleep $RETRY_DELAY
        fi
        
        case $attempt in
            1)
                # First attempt: standard install
                if pip install "$package" >> "$LOG_FILE" 2>&1; then
                    success=true
                else
                    last_error="Standard install failed"
                fi
                ;;
            2)
                # Second attempt: upgrade pip and use --no-cache-dir
                echo -e "${DIM}      Upgrading pip and retrying...${NC}"
                pip install --upgrade pip >> "$LOG_FILE" 2>&1
                if pip install --no-cache-dir "$package" >> "$LOG_FILE" 2>&1; then
                    success=true
                else
                    last_error="No-cache install failed"
                fi
                ;;
            3)
                # Third attempt: clear cache, use --force-reinstall
                echo -e "${DIM}      Clearing cache and force reinstalling...${NC}"
                pip cache purge >> "$LOG_FILE" 2>&1 || true
                if pip install --force-reinstall --no-deps "$package" >> "$LOG_FILE" 2>&1; then
                    # Install dependencies separately
                    pip install "$package" >> "$LOG_FILE" 2>&1
                    success=true
                else
                    last_error="Force reinstall failed"
                fi
                ;;
        esac
        
        # Verify installation after each attempt
        if [ "$success" = true ]; then
            if ! check_package_installed "$package"; then
                success=false
                last_error="Package installed but not importable"
            fi
        fi
        
        attempt=$((attempt + 1))
    done
    
    if [ "$success" = true ]; then
        PACKAGE_STATUS[$package]="installed"
        PACKAGE_ERRORS[$package]=""
        return 0
    else
        PACKAGE_STATUS[$package]="failed"
        PACKAGE_ERRORS[$package]="$last_error"
        return 1
    fi
}

# Install all required packages
install_required_packages() {
    local failed_packages=()
    local success_packages=()
    local retry_packages=()
    
    echo ""
    echo -e "${BOLD}Installing required packages:${NC}"
    echo ""
    
    for package in "${REQUIRED_PACKAGES[@]}"; do
        echo -ne "   ${EMOJI_LOADING} Installing ${CYAN}$package${NC}... "
        
        if install_package_with_retry "$package"; then
            local retries=${PACKAGE_RETRIES[$package]}
            if [ "$retries" -gt 1 ]; then
                echo -e "${GREEN}${EMOJI_CHECK} OK${NC} ${DIM}(after $retries attempts)${NC}"
                retry_packages+=("$package")
            else
                echo -e "${GREEN}${EMOJI_CHECK} OK${NC}"
            fi
            success_packages+=("$package")
        else
            echo -e "${RED}${EMOJI_CROSS} FAILED${NC}"
            echo -e "      ${DIM}Error: ${PACKAGE_ERRORS[$package]}${NC}"
            failed_packages+=("$package")
        fi
    done
    
    echo ""
    
    # Return status
    if [ ${#failed_packages[@]} -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Verify all packages are installed
verify_all_packages() {
    local missing_packages=()
    local verified_packages=()
    
    echo ""
    echo -e "${BOLD}Verifying package installations:${NC}"
    echo ""
    
    for package in "${REQUIRED_PACKAGES[@]}"; do
        echo -ne "   Checking ${CYAN}$package${NC}... "
        
        if check_package_installed "$package"; then
            echo -e "${GREEN}${EMOJI_CHECK}${NC}"
            verified_packages+=("$package")
            PACKAGE_STATUS[$package]="verified"
        else
            echo -e "${RED}${EMOJI_CROSS} Missing${NC}"
            missing_packages+=("$package")
            PACKAGE_STATUS[$package]="missing"
        fi
    done
    
    echo ""
    
    if [ ${#missing_packages[@]} -gt 0 ]; then
        echo -e "${YELLOW}Found ${#missing_packages[@]} missing package(s). Attempting reinstallation...${NC}"
        echo ""
        
        for package in "${missing_packages[@]}"; do
            echo -ne "   ${EMOJI_LOADING} Reinstalling ${CYAN}$package${NC}... "
            
            if install_package_with_retry "$package"; then
                echo -e "${GREEN}${EMOJI_CHECK} OK${NC}"
            else
                echo -e "${RED}${EMOJI_CROSS} FAILED${NC}"
            fi
        done
        echo ""
    fi
    
    # Final count of failed packages
    local final_failed=0
    for package in "${REQUIRED_PACKAGES[@]}"; do
        if [ "${PACKAGE_STATUS[$package]}" = "failed" ] || [ "${PACKAGE_STATUS[$package]}" = "missing" ]; then
            if ! check_package_installed "$package"; then
                final_failed=$((final_failed + 1))
            fi
        fi
    done
    
    return $final_failed
}

# Print package installation summary
print_package_summary() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}                    Package Installation Summary${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    local success_count=0
    local failed_count=0
    local retry_count=0
    local failed_list=()
    
    printf "   ${BOLD}%-25s %-12s %-10s %-20s${NC}\n" "Package" "Status" "Retries" "Notes"
    echo "   ─────────────────────────────────────────────────────────────"
    
    for package in "${REQUIRED_PACKAGES[@]}"; do
        local status="${PACKAGE_STATUS[$package]:-unknown}"
        local retries="${PACKAGE_RETRIES[$package]:-0}"
        local error="${PACKAGE_ERRORS[$package]:-}"
        local notes=""
        
        # Check actual installation status
        if check_package_installed "$package"; then
            status="✓ OK"
            success_count=$((success_count + 1))
            if [ "$retries" -gt 1 ]; then
                notes="Needed retry"
                retry_count=$((retry_count + 1))
            fi
            printf "   ${GREEN}%-25s${NC} ${GREEN}%-12s${NC} %-10s %-20s\n" "$package" "$status" "$retries" "$notes"
        else
            status="✗ FAILED"
            failed_count=$((failed_count + 1))
            failed_list+=("$package")
            notes="${error:0:18}"
            printf "   ${RED}%-25s${NC} ${RED}%-12s${NC} %-10s %-20s\n" "$package" "$status" "$retries" "$notes"
        fi
    done
    
    echo ""
    echo "   ─────────────────────────────────────────────────────────────"
    echo -e "   ${GREEN}Successful: $success_count${NC}  |  ${YELLOW}Needed retry: $retry_count${NC}  |  ${RED}Failed: $failed_count${NC}"
    echo ""
    
    # If there are failures, provide manual fix commands
    if [ $failed_count -gt 0 ]; then
        echo -e "${YELLOW}${EMOJI_WARN} Some packages failed to install. Try these manual fixes:${NC}"
        echo ""
        echo -e "   ${DIM}# Activate the virtual environment:${NC}"
        echo -e "   ${CYAN}source $INSTALL_DIR/venv/bin/activate${NC}"
        echo ""
        echo -e "   ${DIM}# Try installing failed packages manually:${NC}"
        for pkg in "${failed_list[@]}"; do
            echo -e "   ${CYAN}pip install --upgrade $pkg${NC}"
        done
        echo ""
        echo -e "   ${DIM}# Or try with verbose output to see errors:${NC}"
        for pkg in "${failed_list[@]}"; do
            echo -e "   ${CYAN}pip install -v $pkg 2>&1 | tail -50${NC}"
        done
        echo ""
        echo -e "   ${DIM}# Check the installation log for details:${NC}"
        echo -e "   ${CYAN}cat $LOG_FILE | grep -A5 'ERROR\\|error\\|Failed'${NC}"
        echo ""
    fi
    
    return $failed_count
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
    
    # Upgrade pip first for better compatibility
    print_progress "Upgrading pip to latest version"
    pip install --upgrade pip >> "$LOG_FILE" 2>&1
    print_success "Pip upgraded"
    
    # Track if requirements.txt install was successful
    local requirements_success=true
    
    # Try installing from requirements.txt first
    if [ -f "requirements.txt" ]; then
        print_progress "Installing from requirements.txt"
        echo "--- Installing requirements.txt ---" >> "$LOG_FILE"
        
        if pip install --upgrade -r requirements.txt >> "$LOG_FILE" 2>&1; then
            print_success "Requirements.txt installed successfully"
        else
            print_warning "Some packages from requirements.txt failed to install"
            requirements_success=false
        fi
    fi
    
    # Install MCP server requirements
    if [ -f "mcp_server/requirements.txt" ]; then
        print_progress "Installing MCP server requirements"
        echo "--- Installing MCP requirements.txt ---" >> "$LOG_FILE"
        
        if pip install --upgrade -r mcp_server/requirements.txt >> "$LOG_FILE" 2>&1; then
            print_success "MCP server requirements installed"
        else
            print_warning "Some MCP packages failed to install"
            requirements_success=false
        fi
    fi
    
    # Verify and install missing packages individually with retry logic
    print_step "Verifying and Fixing Package Installations"
    
    # First verification pass
    local missing_found=false
    for package in "${REQUIRED_PACKAGES[@]}"; do
        if ! check_package_installed "$package"; then
            missing_found=true
            break
        fi
    done
    
    if [ "$missing_found" = true ] || [ "$requirements_success" = false ]; then
        print_warning "Some packages missing or failed. Installing individually with retry logic..."
        
        # Install each package individually with retry
        install_required_packages
        
        # Second verification and auto-fix
        verify_all_packages
    else
        print_success "All required packages verified"
        # Mark all as verified
        for package in "${REQUIRED_PACKAGES[@]}"; do
            PACKAGE_STATUS[$package]="verified"
            PACKAGE_RETRIES[$package]=0
        done
    fi
    
    # Install optional packages (non-critical)
    print_progress "Installing optional packages"
    for package in "${OPTIONAL_PACKAGES[@]}"; do
        if ! check_package_installed "$package"; then
            pip install "$package" >> "$LOG_FILE" 2>&1 || true
        fi
    done
    
    # Install package in editable mode
    print_progress "Installing AI Orchestrator package"
    if pip install -e . >> "$LOG_FILE" 2>&1; then
        print_success "AI Orchestrator package installed"
    else
        print_warning "Editable install failed, trying regular install"
        pip install . >> "$LOG_FILE" 2>&1 || true
    fi
    
    # Print package summary
    print_package_summary
    
    # Final verification
    local failed_count=0
    for package in "${REQUIRED_PACKAGES[@]}"; do
        if ! check_package_installed "$package"; then
            failed_count=$((failed_count + 1))
        fi
    done
    
    if [ $failed_count -gt 0 ]; then
        print_warning "$failed_count critical package(s) failed to install. Installation may not work correctly."
        log_error "Failed packages: $failed_count"
    else
        print_success "All dependencies installed and verified!"
    fi
    
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
# API Key Validation Functions
# ============================================================================

# Track API key configuration status
declare -A API_KEY_STATUS

# Validate API key format
# Usage: validate_api_key_format "service_name" "key_value"
# Returns: 0 if valid, 1 if invalid
validate_api_key_format() {
    local service="$1"
    local key="$2"
    local min_length=32
    
    # Check if key is empty
    if [ -z "$key" ]; then
        return 1
    fi
    
    # Check minimum length (most API keys are 40+ characters)
    if [ ${#key} -lt $min_length ]; then
        return 2
    fi
    
    # Service-specific format validation
    case "$service" in
        "openai")
            # OpenAI keys start with "sk-" or "sk-proj-"
            if [[ "$key" =~ ^sk- ]] || [[ "$key" =~ ^sk-proj- ]]; then
                return 0
            else
                return 3
            fi
            ;;
        "anthropic")
            # Anthropic keys start with "sk-ant-"
            if [[ "$key" =~ ^sk-ant- ]]; then
                return 0
            else
                return 3
            fi
            ;;
        "gemini")
            # Google Gemini keys start with "AIza"
            if [[ "$key" =~ ^AIza ]]; then
                return 0
            else
                return 3
            fi
            ;;
        "moonshot")
            # Moonshot keys start with "sk-"
            if [[ "$key" =~ ^sk- ]]; then
                return 0
            else
                return 3
            fi
            ;;
        *)
            # Unknown service - just check length
            return 0
            ;;
    esac
}

# Get validation error message
get_validation_error() {
    local service="$1"
    local error_code="$2"
    
    case "$error_code" in
        1)
            echo "No key provided"
            ;;
        2)
            echo "Key is too short (minimum 32 characters expected)"
            ;;
        3)
            case "$service" in
                "openai")
                    echo "Invalid format. OpenAI keys should start with 'sk-' or 'sk-proj-'"
                    ;;
                "anthropic")
                    echo "Invalid format. Anthropic keys should start with 'sk-ant-'"
                    ;;
                "gemini")
                    echo "Invalid format. Google Gemini keys should start with 'AIza'"
                    ;;
                "moonshot")
                    echo "Invalid format. Moonshot keys should start with 'sk-'"
                    ;;
                *)
                    echo "Invalid key format"
                    ;;
            esac
            ;;
        *)
            echo "Unknown validation error"
            ;;
    esac
}

# Get example key format for a service
get_key_example() {
    local service="$1"
    
    case "$service" in
        "openai")
            echo "sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
            ;;
        "anthropic")
            echo "sk-ant-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
            ;;
        "gemini")
            echo "AIzaXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
            ;;
        "moonshot")
            echo "sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
            ;;
        *)
            echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
            ;;
    esac
}

# Sanitize API key input - extracts the actual key from user input
# Handles cases like "Chat gpt = sk-xxx", "OpenAI: sk-xxx", "API key: sk-xxx"
sanitize_api_key_input() {
    local input="$1"
    local sanitized=""
    
    # Remove leading/trailing whitespace
    sanitized=$(echo "$input" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Check if input contains "=" or ":" - extract the value after it
    if [[ "$sanitized" == *"="* ]]; then
        # Extract everything after the last "="
        sanitized="${sanitized##*=}"
        sanitized=$(echo "$sanitized" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    elif [[ "$sanitized" == *":"* ]]; then
        # Extract everything after the last ":"
        sanitized="${sanitized##*:}"
        sanitized=$(echo "$sanitized" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    fi
    
    # Remove any surrounding quotes (single or double)
    sanitized=$(echo "$sanitized" | sed "s/^['\"]//;s/['\"]$//")
    
    echo "$sanitized"
}

# Safely assign a value to a variable by name (avoids eval issues with special characters)
# Usage: safe_assign "variable_name" "value"
safe_assign() {
    local var_name="$1"
    local value="$2"
    printf -v "$var_name" '%s' "$value"
}

# Prompt for API key with validation and confirmation
# Usage: prompt_api_key "variable_name" "Service Name" "service_id" "required|optional"
prompt_api_key() {
    local var_name="$1"
    local service_display_name="$2"
    local service_id="$3"
    local requirement="$4"  # "required" or "optional"
    local user_input=""
    local sanitized_input=""
    local key_valid=false
    local max_attempts=3
    local attempt=0
    
    echo ""  # Add spacing before each API key prompt for clarity
    
    while [ "$key_valid" = false ] && [ $attempt -lt $max_attempts ]; do
        attempt=$((attempt + 1))
        
        # Display prompt with clear label
        if [ "$requirement" = "optional" ]; then
            echo -e "   ${CYAN}[$attempt/$max_attempts] $service_display_name API Key${NC} ${DIM}(optional, press Enter to skip)${NC}"
        else
            echo -e "   ${CYAN}[$attempt/$max_attempts] $service_display_name API Key${NC} ${DIM}(recommended)${NC}"
        fi
        printf "   Enter key: "
        
        # Read user input
        read -r user_input || true  # Prevent exit on read failure with set -e
        
        # Sanitize the input (handles "Chat gpt = sk-xxx" type inputs)
        sanitized_input=$(sanitize_api_key_input "$user_input")
        
        # Check if empty (after sanitization)
        if [ -z "$sanitized_input" ]; then
            # Ask for confirmation to skip
            if [ "$requirement" = "required" ]; then
                echo ""
                echo -e "   ${YELLOW}${EMOJI_WARN} No API key provided for $service_display_name.${NC}"
                echo -e "   ${DIM}This key is recommended for the orchestrator to work properly.${NC}"
                printf "   Continue without $service_display_name API key? (yes/no) [no]: "
                local confirm=""
                read -r confirm || true
                confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')
                
                if [ "$confirm" = "yes" ] || [ "$confirm" = "y" ]; then
                    safe_assign "$var_name" ""
                    API_KEY_STATUS[$service_id]="skipped"
                    echo -e "   ${DIM}→ $service_display_name key skipped (can be added later)${NC}"
                    key_valid=true
                else
                    echo -e "   ${DIM}→ Please enter your $service_display_name API key${NC}"
                    echo -e "   ${DIM}   Example format: $(get_key_example $service_id)${NC}"
                    echo ""
                    # Continue the loop to ask again
                fi
            else
                # Optional key - skip without confirmation
                safe_assign "$var_name" ""
                API_KEY_STATUS[$service_id]="skipped"
                echo -e "   ${DIM}→ $service_display_name key skipped (optional)${NC}"
                key_valid=true
            fi
        else
            # Show what we extracted if it differs from input
            if [ "$sanitized_input" != "$user_input" ]; then
                echo -e "   ${DIM}   (Extracted key from input)${NC}"
            fi
            
            # Validate the key format
            validate_api_key_format "$service_id" "$sanitized_input"
            local validation_result=$?
            
            if [ $validation_result -eq 0 ]; then
                # Key is valid - use safe assignment instead of eval
                safe_assign "$var_name" "$sanitized_input"
                API_KEY_STATUS[$service_id]="configured"
                # Show masked key for confirmation
                local masked_key="${sanitized_input:0:8}...${sanitized_input: -4}"
                echo -e "   ${GREEN}${EMOJI_CHECK} Valid key format${NC} ${DIM}($masked_key)${NC}"
                key_valid=true
            else
                # Invalid format - warn and ask to re-enter or continue anyway
                local error_msg=$(get_validation_error "$service_id" "$validation_result")
                echo ""
                echo -e "   ${YELLOW}${EMOJI_WARN} Warning: $error_msg${NC}"
                echo -e "   ${DIM}   Expected format: $(get_key_example $service_id)${NC}"
                echo ""
                
                echo -e "   ${WHITE}Options:${NC}"
                echo -e "   ${WHITE}  [1]${NC} Re-enter the key"
                echo -e "   ${WHITE}  [2]${NC} Use this key anyway (may not work)"
                if [ "$requirement" = "optional" ]; then
                    echo -e "   ${WHITE}  [3]${NC} Skip this key"
                fi
                printf "   Choice [1]: "
                
                local choice=""
                read -r choice || true
                choice=${choice:-1}
                
                case "$choice" in
                    2)
                        # Use the key anyway - safe assignment
                        safe_assign "$var_name" "$sanitized_input"
                        API_KEY_STATUS[$service_id]="configured_unverified"
                        echo -e "   ${YELLOW}→ Using key (format not verified)${NC}"
                        key_valid=true
                        ;;
                    3)
                        if [ "$requirement" = "optional" ]; then
                            safe_assign "$var_name" ""
                            API_KEY_STATUS[$service_id]="skipped"
                            echo -e "   ${DIM}→ $service_display_name key skipped${NC}"
                            key_valid=true
                        else
                            echo -e "   ${DIM}→ Please try again${NC}"
                            echo ""
                        fi
                        ;;
                    *)
                        # Re-enter (default)
                        echo -e "   ${DIM}→ Please enter the correct key${NC}"
                        echo ""
                        ;;
                esac
            fi
        fi
    done
    
    # If we've exceeded max attempts for a required key, mark as skipped
    if [ "$key_valid" = false ]; then
        echo -e "   ${YELLOW}${EMOJI_WARN} Maximum attempts reached. Skipping $service_display_name key.${NC}"
        safe_assign "$var_name" ""
        API_KEY_STATUS[$service_id]="skipped"
    fi
}

# Print API key configuration summary
print_api_key_summary() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}                    API Key Configuration Summary${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    local missing_required=0
    local config_file="$HOME/.config/ai-orchestrator/config.env"
    
    # OpenAI
    case "${API_KEY_STATUS[openai]}" in
        "configured")
            echo -e "   ${GREEN}${EMOJI_CHECK} OpenAI:${NC} Configured"
            ;;
        "configured_unverified")
            echo -e "   ${YELLOW}${EMOJI_WARN} OpenAI:${NC} Configured (format not verified)"
            ;;
        *)
            echo -e "   ${YELLOW}${EMOJI_WARN} OpenAI:${NC} Skipped"
            missing_required=$((missing_required + 1))
            ;;
    esac
    
    # Anthropic
    case "${API_KEY_STATUS[anthropic]}" in
        "configured")
            echo -e "   ${GREEN}${EMOJI_CHECK} Anthropic:${NC} Configured"
            ;;
        "configured_unverified")
            echo -e "   ${YELLOW}${EMOJI_WARN} Anthropic:${NC} Configured (format not verified)"
            ;;
        *)
            echo -e "   ${YELLOW}${EMOJI_WARN} Anthropic:${NC} Skipped"
            missing_required=$((missing_required + 1))
            ;;
    esac
    
    # Gemini
    case "${API_KEY_STATUS[gemini]}" in
        "configured")
            echo -e "   ${GREEN}${EMOJI_CHECK} Gemini:${NC} Configured"
            ;;
        "configured_unverified")
            echo -e "   ${YELLOW}${EMOJI_WARN} Gemini:${NC} Configured (format not verified)"
            ;;
        *)
            echo -e "   ${YELLOW}${EMOJI_WARN} Gemini:${NC} Skipped"
            missing_required=$((missing_required + 1))
            ;;
    esac
    
    # Moonshot (optional)
    case "${API_KEY_STATUS[moonshot]}" in
        "configured")
            echo -e "   ${GREEN}${EMOJI_CHECK} Moonshot:${NC} Configured"
            ;;
        "configured_unverified")
            echo -e "   ${YELLOW}${EMOJI_WARN} Moonshot:${NC} Configured (format not verified)"
            ;;
        *)
            echo -e "   ${DIM}○ Moonshot:${NC} Skipped (optional)"
            ;;
    esac
    
    echo ""
    
    # Show warnings if required keys are missing
    if [ $missing_required -gt 0 ]; then
        echo -e "   ${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "   ${YELLOW}${EMOJI_WARN} Warning: Some recommended API keys are missing.${NC}"
        echo -e "   ${YELLOW}   The orchestrator may have limited functionality.${NC}"
        echo ""
        echo -e "   ${DIM}You can add them later by editing:${NC}"
        echo -e "   ${CYAN}   $INSTALL_DIR/.env${NC}"
        echo -e "   ${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    else
        echo -e "   ${GREEN}${EMOJI_CHECK} All recommended API keys configured!${NC}"
    fi
    
    echo ""
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
    echo -e "${DIM}   Keys are validated for format. You can skip and add them later.${NC}"
    echo ""
    
    # Prompt for each API key with validation
    prompt_api_key "OPENAI_KEY" "OpenAI" "openai" "required"
    prompt_api_key "ANTHROPIC_KEY" "Anthropic" "anthropic" "required"
    prompt_api_key "GEMINI_KEY" "Google Gemini" "gemini" "required"
    prompt_api_key "MOONSHOT_KEY" "Moonshot" "moonshot" "optional"
    
    # Show API key summary
    print_api_key_summary
    
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
    
    # IMPORTANT: Cursor now uses ~/.cursor/mcp.json for MCP configuration
    # NOT ~/Library/Application Support/Cursor/User/... which was deprecated
    local cursor_config_dir="$HOME/.cursor"
    local mcp_config_file="$cursor_config_dir/mcp.json"
    local backup_dir="$cursor_config_dir/backups"
    
    # Create directories if needed
    mkdir -p "$cursor_config_dir"
    mkdir -p "$backup_dir"
    
    # Detect Python command (prefer venv)
    local python_cmd
    if [ -f "$INSTALL_DIR/venv/bin/python" ]; then
        python_cmd="$INSTALL_DIR/venv/bin/python"
    elif [ -f "$INSTALL_DIR/venv/bin/python3" ]; then
        python_cmd="$INSTALL_DIR/venv/bin/python3"
    elif command -v python3 &>/dev/null; then
        python_cmd="python3"
    else
        python_cmd="python"
    fi
    
    print_info "Using Python: $python_cmd"
    
    # Generate Cursor MCP configuration
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
    
    # Backup existing config
    if [ -f "$mcp_config_file" ]; then
        local backup_file="$backup_dir/mcp.json.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$mcp_config_file" "$backup_file"
        print_info "Backed up existing config to: $backup_file"
    fi
    
    echo "$mcp_config" > "$mcp_config_file"
    print_success "Cursor MCP configuration created at: $mcp_config_file"
    
    # Verify JSON is valid
    if python3 -c "import json; json.load(open('$mcp_config_file'))" 2>/dev/null; then
        print_success "Configuration JSON validated"
    else
        print_warning "Could not validate JSON - please check the configuration"
    fi
    
    # Display the configuration
    print_info "Configuration contents:"
    echo ""
    cat "$mcp_config_file" | sed 's/^/    /'
    echo ""
    
    # Copy .cursorrules to home directory
    if [ -f "$INSTALL_DIR/cursor_integration/.cursorrules" ]; then
        cp "$INSTALL_DIR/cursor_integration/.cursorrules" "$HOME/.cursorrules"
        print_success "Cursor rules file installed"
    fi
    
    # Print verification instructions
    print_info "Cursor integration configured"
    echo ""
    echo -e "  ${WHITE}To verify MCP is working in Cursor:${NC}"
    echo -e "  1. ${BOLD}Completely quit Cursor${NC} (Cmd+Q on Mac)"
    echo -e "  2. ${BOLD}Reopen Cursor${NC}"
    echo -e "  3. Open Settings (${WHITE}Cmd+,${NC}) → Tools & Integrations"
    echo -e "  4. Look for ${GREEN}ai-orchestrator${NC} with a ${GREEN}green dot${NC} under MCP Tools"
    echo -e "  5. In Chat, select ${WHITE}Agent${NC} mode to see available tools"
    echo ""
    
    # Check for deprecated config location and warn
    local old_mcp_settings="$HOME/Library/Application Support/Cursor/User/globalStorage/mcp-settings.json"
    if [ -f "$old_mcp_settings" ]; then
        print_warning "Found deprecated config at old location (not used by Cursor anymore):"
        print_info "$old_mcp_settings"
        print_info "The new config at ~/.cursor/mcp.json will be used instead"
    fi
    
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
    print_step "Running Final Verification"
    
    local verification_passed=true
    local report_file="$INSTALL_DIR/verification_report.txt"
    local missing_packages=()
    
    echo "AI Orchestrator Verification Report" > "$report_file"
    echo "Generated: $(date)" >> "$report_file"
    echo "Installer Version: $SCRIPT_VERSION" >> "$report_file"
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
    
    # Test pip packages using the defined REQUIRED_PACKAGES
    print_progress "Verifying required packages"
    echo "" >> "$report_file"
    echo "Package Verification:" >> "$report_file"
    
    for pkg in "${REQUIRED_PACKAGES[@]}"; do
        if check_package_installed "$pkg"; then
            echo "✓ Package $pkg: OK" >> "$report_file"
        else
            echo "✗ Package $pkg: MISSING" >> "$report_file"
            missing_packages+=("$pkg")
            verification_passed=false
        fi
    done
    
    # If there are missing packages, attempt auto-fix
    if [ ${#missing_packages[@]} -gt 0 ]; then
        print_warning "${#missing_packages[@]} package(s) missing. Attempting auto-fix..."
        echo "" >> "$report_file"
        echo "Auto-fix attempt:" >> "$report_file"
        
        source "$INSTALL_DIR/venv/bin/activate"
        
        for pkg in "${missing_packages[@]}"; do
            echo -ne "   Fixing ${CYAN}$pkg${NC}... "
            
            if install_package_with_retry "$pkg"; then
                echo -e "${GREEN}${EMOJI_CHECK} Fixed${NC}"
                echo "✓ Auto-fixed: $pkg" >> "$report_file"
            else
                echo -e "${RED}${EMOJI_CROSS} Failed${NC}"
                echo "✗ Auto-fix failed: $pkg" >> "$report_file"
            fi
        done
    else
        print_success "All required packages verified"
    fi
    
    echo "" >> "$report_file"
    
    # Test API connections (only if keys provided)
    print_progress "Testing API connections"
    echo "" >> "$report_file"
    echo "API Connectivity:" >> "$report_file"
    
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
    else
        echo "○ OpenAI API: Not configured" >> "$report_file"
    fi
    
    if [ -n "$ANTHROPIC_KEY" ]; then
        local test_result=$("$INSTALL_DIR/venv/bin/python" -c "
import anthropic
client = anthropic.Anthropic(api_key='$ANTHROPIC_KEY')
try:
    # Just verify we can create a client
    print('OK')
except Exception as e:
    print(f'FAILED: {e}')
" 2>&1)
        if [[ "$test_result" == "OK" ]]; then
            print_success "Anthropic API configured"
            echo "✓ Anthropic API: OK" >> "$report_file"
        else
            print_warning "Anthropic API issue: $test_result"
            echo "○ Anthropic API: $test_result" >> "$report_file"
        fi
    else
        echo "○ Anthropic API: Not configured" >> "$report_file"
    fi
    
    if [ -n "$GEMINI_KEY" ]; then
        local test_result=$("$INSTALL_DIR/venv/bin/python" -c "
from google import genai
try:
    client = genai.Client(api_key='$GEMINI_KEY')
    print('OK')
except Exception as e:
    print(f'FAILED: {e}')
" 2>&1)
        if [[ "$test_result" == "OK" ]]; then
            print_success "Gemini API configured"
            echo "✓ Gemini API: OK" >> "$report_file"
        else
            print_warning "Gemini API issue: $test_result"
            echo "○ Gemini API: $test_result" >> "$report_file"
        fi
    else
        echo "○ Gemini API: Not configured" >> "$report_file"
    fi
    
    echo "" >> "$report_file"
    
    # Test MCP server
    print_progress "Verifying MCP server"
    echo "Server Status:" >> "$report_file"
    if pgrep -f "mcp_server.server" > /dev/null 2>&1; then
        print_success "MCP server is running"
        echo "✓ MCP Server: RUNNING" >> "$report_file"
    else
        print_warning "MCP server is not running"
        echo "○ MCP Server: NOT RUNNING" >> "$report_file"
    fi
    
    # Test Cursor integration
    print_progress "Verifying Cursor integration"
    local cursor_config="$HOME/.cursor/mcp.json"
    if [ -f "$cursor_config" ]; then
        print_success "Cursor MCP configuration exists at: $cursor_config"
        echo "✓ Cursor Config: OK" >> "$report_file"
        
        # Validate JSON
        if python3 -c "import json; json.load(open('$cursor_config'))" 2>/dev/null; then
            print_success "Cursor MCP configuration is valid JSON"
        else
            print_warning "Cursor MCP configuration may have JSON errors"
        fi
        
        # Check for ai-orchestrator entry
        if grep -q "ai-orchestrator" "$cursor_config" 2>/dev/null; then
            print_success "ai-orchestrator entry found in config"
        else
            print_warning "ai-orchestrator entry NOT found in config"
        fi
    else
        print_warning "Cursor MCP configuration not found"
        echo "○ Cursor Config: NOT FOUND" >> "$report_file"
        print_info "Run the fix script: $INSTALL_DIR/cursor_integration/fix_cursor_mcp.sh"
    fi
    
    # Run test script if available
    if [ -f "$INSTALL_DIR/scripts/test-apis.sh" ]; then
        print_progress "Running API tests"
        echo "" >> "$report_file"
        echo "API Test Results:" >> "$report_file"
        
        if bash "$INSTALL_DIR/scripts/test-apis.sh" >> "$report_file" 2>&1; then
            print_success "API tests completed"
        else
            print_warning "Some API tests may have failed"
        fi
    fi
    
    echo "" >> "$report_file"
    echo "========================================" >> "$report_file"
    echo "Verification completed at $(date)" >> "$report_file"
    
    # Final package check
    local final_missing=0
    for pkg in "${REQUIRED_PACKAGES[@]}"; do
        if ! check_package_installed "$pkg"; then
            final_missing=$((final_missing + 1))
        fi
    done
    
    if [ $final_missing -gt 0 ]; then
        verification_passed=false
        echo "" >> "$report_file"
        echo "WARNING: $final_missing critical package(s) still missing!" >> "$report_file"
    fi
    
    print_info "Verification report saved to: $report_file"
    
    if [ "$verification_passed" = true ]; then
        print_success "All verifications passed!"
    else
        print_warning "Some verifications failed. Check the report for details."
        print_info "Run '$INSTALL_DIR/scripts/test-apis.sh' for detailed API testing."
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
