#!/bin/bash
# ============================================================================
# AI Orchestrator - View Logs
# ============================================================================
# Usage: ./logs.sh [OPTIONS]
#   -f, --follow    Follow log output (tail -f)
#   -n NUM          Show last NUM lines (default: 50)
#   -e, --errors    Show error log instead
#   --clear         Clear log files
# ============================================================================

# Determine installation directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AI_ORCH_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$AI_ORCH_DIR/logs/mcp-server.log"
ERROR_LOG="$AI_ORCH_DIR/logs/mcp-server.error.log"

# Default options
FOLLOW=false
NUM_LINES=50
SHOW_ERRORS=false
CLEAR_LOGS=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--follow) FOLLOW=true; shift ;;
        -n) NUM_LINES="$2"; shift 2 ;;
        -e|--errors) SHOW_ERRORS=true; shift ;;
        --clear) CLEAR_LOGS=true; shift ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -f, --follow    Follow log output (tail -f)"
            echo "  -n NUM          Show last NUM lines (default: 50)"
            echo "  -e, --errors    Show error log instead"
            echo "  --clear         Clear log files"
            echo "  -h, --help      Show this help message"
            exit 0
            ;;
        *) shift ;;
    esac
done

# Clear logs if requested
if [ "$CLEAR_LOGS" = true ]; then
    echo "Clearing log files..."
    > "$LOG_FILE" 2>/dev/null || true
    > "$ERROR_LOG" 2>/dev/null || true
    echo "✓ Logs cleared"
    exit 0
fi

# Select log file
if [ "$SHOW_ERRORS" = true ]; then
    TARGET_LOG="$ERROR_LOG"
    TITLE="Error Log"
else
    TARGET_LOG="$LOG_FILE"
    TITLE="Server Log"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📋 AI Orchestrator - $TITLE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  File: $TARGET_LOG"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if log exists
if [ ! -f "$TARGET_LOG" ]; then
    echo ""
    echo "  (No log file found)"
    echo ""
    exit 0
fi

echo ""

# Display logs
if [ "$FOLLOW" = true ]; then
    tail -f "$TARGET_LOG"
else
    tail -n "$NUM_LINES" "$TARGET_LOG"
fi
