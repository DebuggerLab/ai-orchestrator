#!/bin/bash
# ============================================================================
# AI Orchestrator - API Test Script
# ============================================================================
# Tests connectivity to all configured AI APIs
# Usage: ./scripts/test-apis.sh
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Emojis
EMOJI_CHECK="✅"
EMOJI_CROSS="❌"
EMOJI_WARN="⚠️"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load environment
if [ -f "$PROJECT_DIR/.env" ]; then
    source "$PROJECT_DIR/.env"
fi

# Activate virtual environment
if [ -d "$PROJECT_DIR/venv" ]; then
    source "$PROJECT_DIR/venv/bin/activate"
fi

echo ""
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}                    AI Orchestrator API Tests${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Track results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Test a package
test_package() {
    local package="$1"
    local import_name="$2"
    
    echo -ne "   Testing ${CYAN}$package${NC}... "
    
    if python -c "import $import_name" 2>/dev/null; then
        echo -e "${GREEN}${EMOJI_CHECK} OK${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}${EMOJI_CROSS} Not installed${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test an API connection
test_api() {
    local name="$1"
    local key_var="$2"
    local test_code="$3"
    
    local key_value="${!key_var}"
    
    echo -ne "   Testing ${CYAN}$name API${NC}... "
    
    if [ -z "$key_value" ]; then
        echo -e "${YELLOW}${EMOJI_WARN} Skipped (no API key)${NC}"
        TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
        return 2
    fi
    
    local result
    result=$(python -c "$test_code" 2>&1)
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}${EMOJI_CHECK} OK${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}${EMOJI_CROSS} Failed${NC}"
        echo -e "      ${RED}Error: ${result}${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# ===========================================
# Package Tests
# ===========================================
echo -e "${BOLD}Package Installation Tests:${NC}"
echo ""

test_package "openai" "openai"
test_package "anthropic" "anthropic"
test_package "google-generativeai" "google.generativeai"
test_package "rich" "rich"
test_package "click" "click"
test_package "pydantic" "pydantic"
test_package "python-dotenv" "dotenv"
test_package "requests" "requests"

echo ""

# ===========================================
# API Connection Tests
# ===========================================
echo -e "${BOLD}API Connection Tests:${NC}"
echo ""

# OpenAI Test
test_api "OpenAI" "OPENAI_API_KEY" "
import openai
import os
client = openai.OpenAI(api_key=os.environ.get('OPENAI_API_KEY'))
models = client.models.list()
if not models.data:
    raise Exception('No models returned')
"

# Anthropic Test
test_api "Anthropic" "ANTHROPIC_API_KEY" "
import anthropic
import os
client = anthropic.Anthropic(api_key=os.environ.get('ANTHROPIC_API_KEY'))
# Just verify client creation works
"

# Gemini Test
test_api "Gemini" "GEMINI_API_KEY" "
import google.generativeai as genai
import os
genai.configure(api_key=os.environ.get('GEMINI_API_KEY'))
models = genai.list_models()
# Verify we can list models
"

# Moonshot Test
test_api "Moonshot" "MOONSHOT_API_KEY" "
import requests
import os
key = os.environ.get('MOONSHOT_API_KEY')
response = requests.get(
    'https://api.moonshot.cn/v1/models',
    headers={'Authorization': f'Bearer {key}'},
    timeout=10
)
if response.status_code != 200:
    raise Exception(f'Status code: {response.status_code}')
"

echo ""

# ===========================================
# AI Orchestrator Module Tests
# ===========================================
echo -e "${BOLD}AI Orchestrator Module Tests:${NC}"
echo ""

echo -ne "   Testing ${CYAN}ai_orchestrator${NC}... "
if python -c "from ai_orchestrator import Orchestrator" 2>/dev/null; then
    echo -e "${GREEN}${EMOJI_CHECK} OK${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}${EMOJI_CROSS} Failed${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo -ne "   Testing ${CYAN}model clients${NC}... "
if python -c "
from ai_orchestrator.models import OpenAIClient, AnthropicClient, GeminiClient
" 2>/dev/null; then
    echo -e "${GREEN}${EMOJI_CHECK} OK${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}${EMOJI_CROSS} Failed${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo -ne "   Testing ${CYAN}execution module${NC}... "
if python -c "
from ai_orchestrator.execution import ProjectRunner, ErrorDetector, AutoFixer
" 2>/dev/null; then
    echo -e "${GREEN}${EMOJI_CHECK} OK${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}${EMOJI_CROSS} Failed${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo ""

# ===========================================
# Summary
# ===========================================
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}                         Test Summary${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "   ${GREEN}Passed:${NC}  $TESTS_PASSED"
echo -e "   ${RED}Failed:${NC}  $TESTS_FAILED"
echo -e "   ${YELLOW}Skipped:${NC} $TESTS_SKIPPED"
echo ""

TOTAL=$((TESTS_PASSED + TESTS_FAILED))
if [ $TOTAL -gt 0 ]; then
    PERCENTAGE=$((TESTS_PASSED * 100 / TOTAL))
    echo -e "   Success Rate: ${BOLD}${PERCENTAGE}%${NC}"
fi

echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}${EMOJI_CHECK} All tests passed!${NC}"
    exit 0
else
    echo -e "${YELLOW}${EMOJI_WARN} Some tests failed. Check the errors above.${NC}"
    exit 1
fi
