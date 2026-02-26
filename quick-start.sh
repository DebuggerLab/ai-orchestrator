#!/bin/bash
# ============================================================================
# AI Orchestrator - Quick Start Script
# ============================================================================
# This script activates the virtual environment and runs the CLI.
# Use this to avoid having to remember to activate venv every time.
#
# Usage:
#   ./quick-start.sh --help
#   ./quick-start.sh status
#   ./quick-start.sh run "Your task here"
#   ./quick-start.sh ask openai "Your question"
# ============================================================================

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define paths
VENV_PATH="$SCRIPT_DIR/venv"
VENV_ACTIVATE="$VENV_PATH/bin/activate"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ============================================================================
# Check if venv exists
# ============================================================================
if [ ! -d "$VENV_PATH" ]; then
    echo -e "${RED}Error: Virtual environment not found at $VENV_PATH${NC}"
    echo ""
    echo "Please run the installation script first:"
    echo "  ./install.sh"
    echo ""
    echo "Or create it manually:"
    echo "  python3 -m venv venv"
    echo "  source venv/bin/activate"
    echo "  pip install -r requirements.txt"
    echo "  pip install -e ."
    exit 1
fi

# ============================================================================
# Check if .env exists
# ============================================================================
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    # Check for system-wide config
    if [ ! -f "$HOME/.config/ai-orchestrator/config.env" ]; then
        echo -e "${YELLOW}Warning: No .env file found${NC}"
        echo ""
        echo "Please create one from the example:"
        echo "  cp .env.example .env"
        echo "  nano .env  # Add your API keys"
        echo ""
    fi
fi

# ============================================================================
# Activate venv and run CLI
# ============================================================================

# Source the virtual environment
source "$VENV_ACTIVATE"

# Change to the script directory (where .env is)
cd "$SCRIPT_DIR"

# If no arguments, show help
if [ $# -eq 0 ]; then
    echo -e "${GREEN}AI Orchestrator Quick Start${NC}"
    echo ""
    echo "This script activates the virtual environment and runs the CLI."
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  ./quick-start.sh <command> [options]"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  ./quick-start.sh --help          # Show all commands"
    echo "  ./quick-start.sh status          # Check configuration"
    echo "  ./quick-start.sh test-api        # Test API connections"
    echo "  ./quick-start.sh run \"Task\"      # Run a task"
    echo "  ./quick-start.sh ask openai \"Q\" # Ask a specific model"
    echo ""
    echo -e "${YELLOW}Alternative (manual activation):${NC}"
    echo "  source venv/bin/activate"
    echo "  ai-orchestrator --help"
    echo ""
    exit 0
fi

# Run the CLI with all provided arguments
exec ai-orchestrator "$@"
