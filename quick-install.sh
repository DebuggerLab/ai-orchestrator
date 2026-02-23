#!/bin/bash
# ============================================================================
# AI Orchestrator - Quick Installation Script (Non-Interactive)
# ============================================================================
# For CI/CD or scripted deployments. Accepts configuration via environment
# variables and uses sensible defaults.
#
# Environment Variables:
#   OPENAI_API_KEY      - OpenAI API key (required)
#   ANTHROPIC_API_KEY   - Anthropic API key (required)
#   GEMINI_API_KEY      - Google Gemini API key (optional)
#   MOONSHOT_API_KEY    - Moonshot API key (optional)
#   INSTALL_DIR         - Installation directory (default: ~/ai-orchestrator)
#   MCP_PORT            - MCP server port (default: 3000)
#   AUTO_START          - Enable auto-start (default: yes)
#   SKIP_VERIFICATION   - Skip verification step (default: no)
#
# Usage:
#   OPENAI_API_KEY=sk-... ANTHROPIC_API_KEY=sk-... ./quick-install.sh
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1" >&2; }
print_info() { echo -e "${CYAN}ℹ${NC} $1"; }
print_warn() { echo -e "${YELLOW}⚠${NC} $1"; }

# Configuration with defaults
INSTALL_DIR="${INSTALL_DIR:-$HOME/ai-orchestrator}"
MCP_PORT="${MCP_PORT:-3000}"
AUTO_START="${AUTO_START:-yes}"
SKIP_VERIFICATION="${SKIP_VERIFICATION:-no}"
OPENAI_MODEL="${OPENAI_MODEL:-gpt-4o-mini}"
ANTHROPIC_MODEL="${ANTHROPIC_MODEL:-claude-3-5-sonnet-20241022}"
GEMINI_MODEL="${GEMINI_MODEL:-gemini-2.5-flash}"
MOONSHOT_MODEL="${MOONSHOT_MODEL:-moonshot-v1-8k}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  AI Orchestrator Quick Install (Non-Interactive)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Validate required keys
if [ -z "$OPENAI_API_KEY" ]; then
    print_error "OPENAI_API_KEY is required"
    exit 1
fi

if [ -z "$ANTHROPIC_API_KEY" ]; then
    print_error "ANTHROPIC_API_KEY is required"
    exit 1
fi

print_info "Installation directory: $INSTALL_DIR"
print_info "MCP port: $MCP_PORT"
print_info "Auto-start: $AUTO_START"

# Check OS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is for macOS only"
    exit 1
fi
print_status "macOS detected"

# Install Xcode CLI tools
if ! xcode-select -p &> /dev/null; then
    print_info "Installing Xcode CLI tools..."
    xcode-select --install 2>/dev/null || true
    until xcode-select -p &> /dev/null; do
        sleep 5
    done
fi
print_status "Xcode CLI tools ready"

# Install Homebrew
if ! command -v brew &> /dev/null; then
    print_info "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
fi
print_status "Homebrew ready"

# Install Python 3.11+
PYTHON_CMD=""
for cmd in python3.12 python3.11 python3; do
    if command -v $cmd &> /dev/null; then
        ver=$($cmd -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
        major=$(echo $ver | cut -d. -f1)
        minor=$(echo $ver | cut -d. -f2)
        if [ "$major" -ge 3 ] && [ "$minor" -ge 11 ]; then
            PYTHON_CMD=$cmd
            break
        fi
    fi
done

if [ -z "$PYTHON_CMD" ]; then
    print_info "Installing Python 3.11..."
    brew install python@3.11
    PYTHON_CMD="python3.11"
fi
print_status "Python ready ($PYTHON_CMD)"

# Setup installation directory
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Clone or copy repository
if [ -d "/home/ubuntu/ai_orchestrator" ]; then
    cp -r /home/ubuntu/ai_orchestrator/* "$INSTALL_DIR/" 2>/dev/null || true
else
    if [ -d ".git" ]; then
        git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || true
    else
        git clone https://github.com/dipcse07/ai-orchestrator.git . 2>/dev/null || true
    fi
fi
print_status "Repository ready"

# Setup virtual environment
if [ ! -d "venv" ]; then
    $PYTHON_CMD -m venv venv
fi
source venv/bin/activate
pip install --upgrade pip -q
print_status "Virtual environment ready"

# Install dependencies
[ -f "requirements.txt" ] && pip install -r requirements.txt -q
[ -f "mcp_server/requirements.txt" ] && pip install -r mcp_server/requirements.txt -q
pip install -e . -q
print_status "Dependencies installed"

# Generate .env file
cat > .env << EOF
# AI Orchestrator Configuration (Quick Install)
# Generated: $(date)

OPENAI_API_KEY=$OPENAI_API_KEY
ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY
GEMINI_API_KEY=${GEMINI_API_KEY:-}
MOONSHOT_API_KEY=${MOONSHOT_API_KEY:-}

OPENAI_MODEL=$OPENAI_MODEL
ANTHROPIC_MODEL=$ANTHROPIC_MODEL
GEMINI_MODEL=$GEMINI_MODEL
MOONSHOT_MODEL=$MOONSHOT_MODEL

MCP_SERVER_PORT=$MCP_PORT
MCP_SERVER_HOST=localhost

MAX_FIX_ATTEMPTS=5
MAX_SAME_ERROR_ATTEMPTS=3
MAX_VERIFICATION_CYCLES=10
FIX_CONFIDENCE_THRESHOLD=0.7
AI_FIX_CONFIDENCE_THRESHOLD=0.6
EXECUTION_TIMEOUT=300
MAX_RETRIES=3
LOG_LEVEL=INFO

INSTALL_DIR=$INSTALL_DIR
INSTALL_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
chmod 600 .env
print_status "Configuration generated"

# Setup MCP server
mkdir -p logs
[ -f "mcp_server/start.sh" ] && chmod +x mcp_server/start.sh
ln -sf "$INSTALL_DIR/.env" "$INSTALL_DIR/mcp_server/.env" 2>/dev/null || true
print_status "MCP server configured"

# Setup Cursor integration
CURSOR_CONFIG_DIR="$HOME/Library/Application Support/Cursor/User/globalStorage"
mkdir -p "$CURSOR_CONFIG_DIR"
cat > "$CURSOR_CONFIG_DIR/mcp-settings.json" << EOF
{
  "mcpServers": {
    "ai-orchestrator": {
      "command": "$INSTALL_DIR/venv/bin/python",
      "args": ["-m", "mcp_server.server"],
      "cwd": "$INSTALL_DIR",
      "env": { "PYTHONPATH": "$INSTALL_DIR" }
    }
  }
}
EOF
print_status "Cursor integration configured"

# Setup launch agent
if [ "$AUTO_START" = "yes" ]; then
    PLIST_FILE="$HOME/Library/LaunchAgents/com.ai-orchestrator.mcp-server.plist"
    mkdir -p "$HOME/Library/LaunchAgents"
    cat > "$PLIST_FILE" << EOF
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
    </dict>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$INSTALL_DIR/logs/mcp-server.log</string>
    <key>StandardErrorPath</key>
    <string>$INSTALL_DIR/logs/mcp-server.error.log</string>
</dict>
</plist>
EOF
    launchctl unload "$PLIST_FILE" 2>/dev/null || true
    launchctl load "$PLIST_FILE"
    print_status "Auto-start enabled"
fi

# Start MCP server
export PYTHONPATH="$INSTALL_DIR"
nohup "$INSTALL_DIR/venv/bin/python" -m mcp_server.server > "$INSTALL_DIR/logs/mcp-server.log" 2>&1 &
sleep 2
if pgrep -f "mcp_server.server" > /dev/null 2>&1; then
    print_status "MCP server started"
else
    print_warn "MCP server may not have started"
fi

# Verification
if [ "$SKIP_VERIFICATION" != "yes" ]; then
    print_info "Running verification..."
    "$INSTALL_DIR/venv/bin/python" -c "import openai, anthropic, rich, click, pydantic" && print_status "Packages verified"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✓ Installation complete!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Installation: $INSTALL_DIR"
echo "  Restart Cursor IDE to enable MCP integration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
