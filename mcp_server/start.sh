#!/bin/bash
#
# AI Orchestrator MCP Server Startup Script
#
# This script starts the MCP server with proper environment setup.
# Usage: ./start.sh

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Change to the project directory
cd "$PROJECT_DIR"

# Set PYTHONPATH to include the project root
export PYTHONPATH="$PROJECT_DIR:$PYTHONPATH"

# Load environment variables from .env if it exists
if [ -f "$PROJECT_DIR/.env" ]; then
    set -a
    source "$PROJECT_DIR/.env"
    set +a
fi

# Run the MCP server
exec python "$SCRIPT_DIR/server.py"
