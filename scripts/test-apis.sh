#!/bin/bash
# ============================================================================
# AI Orchestrator - Test API Connections
# ============================================================================
# Tests all configured API keys to verify connectivity.
# ============================================================================

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

print_status() { echo -e "  ${GREEN}✓${NC} $1"; }
print_error() { echo -e "  ${RED}✗${NC} $1"; }
print_warn() { echo -e "  ${YELLOW}○${NC} $1"; }
print_info() { echo -e "  ${CYAN}ℹ${NC} $1"; }

# Determine installation directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AI_ORCH_DIR="$(dirname "$SCRIPT_DIR")"

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}            ${BOLD}AI Orchestrator API Test${NC}                          ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check .env file
if [ ! -f "$AI_ORCH_DIR/.env" ]; then
    print_error ".env file not found at $AI_ORCH_DIR/.env"
    echo "  Run install.sh to configure your API keys."
    exit 1
fi

# Load environment
set -a
source "$AI_ORCH_DIR/.env"
set +a

# Activate virtual environment
if [ -d "$AI_ORCH_DIR/venv" ]; then
    source "$AI_ORCH_DIR/venv/bin/activate"
else
    print_error "Virtual environment not found"
    exit 1
fi

# Track results
PASSED=0
FAILED=0
SKIPPED=0

echo -e "${BOLD}Testing API Connections...${NC}"
echo ""

# Test OpenAI
echo -e "${BOLD}OpenAI API:${NC}"
if [ -n "$OPENAI_API_KEY" ]; then
    RESULT=$(python3 -c "
import openai
client = openai.OpenAI()
try:
    models = client.models.list()
    print('OK')
except openai.AuthenticationError:
    print('AUTH_ERROR')
except Exception as e:
    print(f'ERROR: {type(e).__name__}')
" 2>&1)
    if [ "$RESULT" = "OK" ]; then
        print_status "Connection successful"
        print_info "Model: ${OPENAI_MODEL:-gpt-4o-mini}"
        ((PASSED++))
    elif [ "$RESULT" = "AUTH_ERROR" ]; then
        print_error "Authentication failed - check your API key"
        ((FAILED++))
    else
        print_error "$RESULT"
        ((FAILED++))
    fi
else
    print_warn "API key not configured (skipped)"
    ((SKIPPED++))
fi
echo ""

# Test Anthropic
echo -e "${BOLD}Anthropic API:${NC}"
if [ -n "$ANTHROPIC_API_KEY" ]; then
    RESULT=$(python3 -c "
import anthropic
client = anthropic.Anthropic()
try:
    # Simple test - create a minimal message
    msg = client.messages.create(
        model='claude-3-5-sonnet-20241022',
        max_tokens=10,
        messages=[{'role': 'user', 'content': 'Hi'}]
    )
    print('OK')
except anthropic.AuthenticationError:
    print('AUTH_ERROR')
except Exception as e:
    print(f'ERROR: {type(e).__name__}')
" 2>&1)
    if [ "$RESULT" = "OK" ]; then
        print_status "Connection successful"
        print_info "Model: ${ANTHROPIC_MODEL:-claude-3-5-sonnet-20241022}"
        ((PASSED++))
    elif [ "$RESULT" = "AUTH_ERROR" ]; then
        print_error "Authentication failed - check your API key"
        ((FAILED++))
    else
        print_error "$RESULT"
        ((FAILED++))
    fi
else
    print_warn "API key not configured (skipped)"
    ((SKIPPED++))
fi
echo ""

# Test Google Gemini
echo -e "${BOLD}Google Gemini API:${NC}"
if [ -n "$GEMINI_API_KEY" ]; then
    RESULT=$(python3 -c "
import google.generativeai as genai
genai.configure(api_key='$GEMINI_API_KEY')
try:
    models = list(genai.list_models())
    print('OK')
except Exception as e:
    if 'API_KEY_INVALID' in str(e) or 'INVALID_ARGUMENT' in str(e):
        print('AUTH_ERROR')
    else:
        print(f'ERROR: {type(e).__name__}')
" 2>&1)
    if [ "$RESULT" = "OK" ]; then
        print_status "Connection successful"
        print_info "Model: ${GEMINI_MODEL:-gemini-2.5-flash}"
        ((PASSED++))
    elif [ "$RESULT" = "AUTH_ERROR" ]; then
        print_error "Authentication failed - check your API key"
        ((FAILED++))
    else
        print_error "$RESULT"
        ((FAILED++))
    fi
else
    print_warn "API key not configured (skipped)"
    ((SKIPPED++))
fi
echo ""

# Test Moonshot
echo -e "${BOLD}Moonshot API:${NC}"
if [ -n "$MOONSHOT_API_KEY" ]; then
    RESULT=$(python3 -c "
import requests
headers = {'Authorization': f'Bearer $MOONSHOT_API_KEY'}
try:
    resp = requests.get('https://api.moonshot.cn/v1/models', headers=headers, timeout=10)
    if resp.status_code == 200:
        print('OK')
    elif resp.status_code == 401:
        print('AUTH_ERROR')
    else:
        print(f'ERROR: HTTP {resp.status_code}')
except Exception as e:
    print(f'ERROR: {type(e).__name__}')
" 2>&1)
    if [ "$RESULT" = "OK" ]; then
        print_status "Connection successful"
        print_info "Model: ${MOONSHOT_MODEL:-moonshot-v1-8k}"
        ((PASSED++))
    elif [ "$RESULT" = "AUTH_ERROR" ]; then
        print_error "Authentication failed - check your API key"
        ((FAILED++))
    else
        print_error "$RESULT"
        ((FAILED++))
    fi
else
    print_warn "API key not configured (skipped)"
    ((SKIPPED++))
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BOLD}Summary:${NC}"
echo -e "  ${GREEN}Passed:${NC}  $PASSED"
echo -e "  ${RED}Failed:${NC}  $FAILED"
echo -e "  ${YELLOW}Skipped:${NC} $SKIPPED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $FAILED -gt 0 ]; then
    exit 1
fi
