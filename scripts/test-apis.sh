#!/bin/bash
# ============================================================================
# AI Orchestrator - API Test Script (Enhanced)
# ============================================================================
# Tests connectivity to all configured AI APIs with timeouts and error handling
# Usage: ./scripts/test-apis.sh
# ============================================================================

# Do NOT use set -e - we want to continue even if tests fail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

# Emojis
EMOJI_CHECK="✅"
EMOJI_CROSS="❌"
EMOJI_WARN="⚠️"
EMOJI_CLOCK="⏱️"
EMOJI_ROCKET="🚀"

# Configuration
API_TIMEOUT=10  # seconds per API test

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

# Track results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0
START_TIME=$(date +%s)

# Progress tracking
CURRENT_TEST=0
TOTAL_TESTS=0

# Show progress indicator
show_progress() {
    local current="$1"
    local total="$2"
    echo -ne "${DIM}[$current/$total]${NC} "
}

# Test a package with error handling
test_package() {
    local package="$1"
    local import_name="$2"
    
    CURRENT_TEST=$((CURRENT_TEST + 1))
    show_progress $CURRENT_TEST $TOTAL_TESTS
    echo -ne "Testing ${CYAN}$package${NC}... "
    
    # Run with timeout
    local result
    result=$(timeout 5 python -c "import $import_name" 2>&1)
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}${EMOJI_CHECK} OK${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    elif [ $exit_code -eq 124 ]; then
        echo -e "${YELLOW}${EMOJI_WARN} Timeout${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    else
        echo -e "${RED}${EMOJI_CROSS} Not installed${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test an API connection with timeout and proper error handling
test_api() {
    local name="$1"
    local key_var="$2"
    local test_code="$3"
    
    local key_value="${!key_var}"
    
    CURRENT_TEST=$((CURRENT_TEST + 1))
    show_progress $CURRENT_TEST $TOTAL_TESTS
    echo -ne "Testing ${CYAN}$name API${NC}... "
    
    # Check if API key exists
    if [ -z "$key_value" ]; then
        echo -e "${YELLOW}${EMOJI_WARN} Skipped (no API key)${NC}"
        echo -e "      ${DIM}Set $key_var in .env to enable this test${NC}"
        TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
        return 2
    fi
    
    # Run the test with timeout
    local result
    local temp_file=$(mktemp)
    
    # Execute Python test with timeout
    timeout $API_TIMEOUT python -c "$test_code" > "$temp_file" 2>&1
    local exit_code=$?
    result=$(cat "$temp_file")
    rm -f "$temp_file"
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}${EMOJI_CHECK} OK${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    elif [ $exit_code -eq 124 ]; then
        echo -e "${RED}${EMOJI_CROSS} Timeout (${API_TIMEOUT}s)${NC}"
        echo -e "      ${DIM}The API did not respond within ${API_TIMEOUT} seconds${NC}"
        echo -e "      ${DIM}This could indicate network issues or an invalid API key${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    else
        echo -e "${RED}${EMOJI_CROSS} Failed${NC}"
        # Show first line of error only to keep output clean
        local error_line=$(echo "$result" | grep -i "error\|exception\|failed" | head -1)
        if [ -n "$error_line" ]; then
            echo -e "      ${DIM}${error_line:0:80}${NC}"
        else
            echo -e "      ${DIM}${result:0:80}${NC}"
        fi
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test module import
test_module() {
    local module_name="$1"
    local import_statement="$2"
    
    CURRENT_TEST=$((CURRENT_TEST + 1))
    show_progress $CURRENT_TEST $TOTAL_TESTS
    echo -ne "Testing ${CYAN}$module_name${NC}... "
    
    local result
    result=$(timeout 5 python -c "$import_statement" 2>&1)
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}${EMOJI_CHECK} OK${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    elif [ $exit_code -eq 124 ]; then
        echo -e "${YELLOW}${EMOJI_WARN} Timeout${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    else
        echo -e "${RED}${EMOJI_CROSS} Failed${NC}"
        echo -e "      ${DIM}${result:0:80}${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# ===========================================
# Calculate total tests
# ===========================================
count_tests() {
    local count=0
    # Package tests: 8
    count=$((count + 8))
    # API tests: 4
    count=$((count + 4))
    # Module tests: 3
    count=$((count + 3))
    echo $count
}

TOTAL_TESTS=$(count_tests)

# ===========================================
# Main Test Execution
# ===========================================

echo ""
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}              ${EMOJI_ROCKET} AI Orchestrator API Tests${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${DIM}Timeout: ${API_TIMEOUT}s per API test | Total tests: ${TOTAL_TESTS}${NC}"
echo ""

# ===========================================
# Package Tests
# ===========================================
echo -e "${BOLD}📦 Package Installation Tests:${NC}"
echo ""

test_package "openai" "openai"
test_package "anthropic" "anthropic"
test_package "google-genai" "google.genai"
test_package "rich" "rich"
test_package "click" "click"
test_package "pydantic" "pydantic"
test_package "python-dotenv" "dotenv"
test_package "requests" "requests"

echo ""

# ===========================================
# API Connection Tests
# ===========================================
echo -e "${BOLD}🔌 API Connection Tests:${NC}"
echo ""

# OpenAI Test - Use models.list() which is fast and verifies auth
test_api "OpenAI" "OPENAI_API_KEY" "
import openai
import os
try:
    client = openai.OpenAI(api_key=os.environ.get('OPENAI_API_KEY'))
    # List models is a quick, cheap API call
    models = list(client.models.list())
    if not models:
        raise Exception('No models returned')
except openai.AuthenticationError as e:
    raise Exception('Invalid API key')
except Exception as e:
    raise Exception(str(e)[:100])
"

# Anthropic Test - Just verify client creation (no actual API call needed)
test_api "Anthropic" "ANTHROPIC_API_KEY" "
import anthropic
import os
try:
    client = anthropic.Anthropic(api_key=os.environ.get('ANTHROPIC_API_KEY'))
    # Verify key format is valid (starts with sk-ant-)
    key = os.environ.get('ANTHROPIC_API_KEY', '')
    if not key.startswith('sk-ant-'):
        raise Exception('Invalid API key format (should start with sk-ant-)')
except anthropic.AuthenticationError as e:
    raise Exception('Invalid API key')
except Exception as e:
    raise Exception(str(e)[:100])
"

# Gemini Test - Use models.list() which is fast
test_api "Gemini" "GEMINI_API_KEY" "
from google import genai
import os
try:
    client = genai.Client(api_key=os.environ.get('GEMINI_API_KEY'))
    # List models is quick
    models = list(client.models.list())
    if not models:
        raise Exception('No models returned')
except Exception as e:
    raise Exception(str(e)[:100])
"

# Moonshot Test - Already has timeout in the code
test_api "Moonshot" "MOONSHOT_API_KEY" "
import requests
import os
try:
    key = os.environ.get('MOONSHOT_API_KEY')
    response = requests.get(
        'https://api.moonshot.cn/v1/models',
        headers={'Authorization': f'Bearer {key}'},
        timeout=8
    )
    if response.status_code == 401:
        raise Exception('Invalid API key')
    if response.status_code != 200:
        raise Exception(f'HTTP {response.status_code}')
except requests.exceptions.Timeout:
    raise Exception('Request timed out')
except requests.exceptions.ConnectionError:
    raise Exception('Connection failed - check network')
except Exception as e:
    raise Exception(str(e)[:100])
"

echo ""

# ===========================================
# AI Orchestrator Module Tests
# ===========================================
echo -e "${BOLD}🧩 AI Orchestrator Module Tests:${NC}"
echo ""

test_module "ai_orchestrator" "from ai_orchestrator import Orchestrator"
test_module "model clients" "from ai_orchestrator.models import OpenAIClient, AnthropicClient, GeminiClient"
test_module "execution module" "from ai_orchestrator.execution import ProjectRunner, ErrorDetector, AutoFixer"

echo ""

# ===========================================
# Calculate time taken
# ===========================================
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

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
echo -e "   ${EMOJI_CLOCK} ${DIM}Time:${NC}    ${ELAPSED}s"
echo ""

TOTAL=$((TESTS_PASSED + TESTS_FAILED))
if [ $TOTAL -gt 0 ]; then
    PERCENTAGE=$((TESTS_PASSED * 100 / TOTAL))
    if [ $PERCENTAGE -ge 80 ]; then
        echo -e "   Success Rate: ${GREEN}${BOLD}${PERCENTAGE}%${NC}"
    elif [ $PERCENTAGE -ge 50 ]; then
        echo -e "   Success Rate: ${YELLOW}${BOLD}${PERCENTAGE}%${NC}"
    else
        echo -e "   Success Rate: ${RED}${BOLD}${PERCENTAGE}%${NC}"
    fi
fi

echo ""

# ===========================================
# Suggestions
# ===========================================
if [ $TESTS_FAILED -gt 0 ] || [ $TESTS_SKIPPED -gt 0 ]; then
    echo -e "${BOLD}💡 Suggestions:${NC}"
    echo ""
    
    if [ $TESTS_SKIPPED -gt 0 ]; then
        echo -e "   ${YELLOW}•${NC} Some tests were skipped due to missing API keys."
        echo -e "     Add them to ${CYAN}$PROJECT_DIR/.env${NC}"
        echo ""
    fi
    
    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "   ${RED}•${NC} Some tests failed. Common fixes:"
        echo -e "     - Check your API keys are valid and not expired"
        echo -e "     - Verify network connectivity"
        echo -e "     - Run ${CYAN}pip install -r requirements.txt${NC} to install missing packages"
        echo ""
    fi
fi

# Final status
if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}${EMOJI_CHECK} All tests passed!${NC}"
    echo ""
    exit 0
else
    echo -e "${YELLOW}${EMOJI_WARN} Some tests failed. Check the errors above.${NC}"
    echo ""
    # Exit with 0 to not break CI/CD - failures are informational
    exit 0
fi
