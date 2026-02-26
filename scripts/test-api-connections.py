#!/usr/bin/env python3
"""
Test API connections for all configured models.
This script directly tests each API to verify keys work correctly.
"""

import os
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from ai_orchestrator.config import Config


def test_openai(api_key: str, model: str) -> tuple[bool, str]:
    """Test OpenAI API connection."""
    try:
        from openai import OpenAI
        client = OpenAI(api_key=api_key)
        response = client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": "Say 'OK' and nothing else"}],
            max_tokens=10
        )
        content = response.choices[0].message.content
        return True, f"Response: {content}"
    except Exception as e:
        return False, str(e)


def test_anthropic(api_key: str, model: str) -> tuple[bool, str]:
    """Test Anthropic API connection."""
    try:
        import anthropic
        client = anthropic.Anthropic(api_key=api_key)
        response = client.messages.create(
            model=model,
            max_tokens=10,
            messages=[{"role": "user", "content": "Say 'OK' and nothing else"}]
        )
        content = response.content[0].text if response.content else ""
        return True, f"Response: {content}"
    except Exception as e:
        return False, str(e)


def test_gemini(api_key: str, model: str) -> tuple[bool, str]:
    """Test Google Gemini API connection."""
    try:
        from google import genai
        from google.genai import types
        
        client = genai.Client(api_key=api_key)
        response = client.models.generate_content(
            model=model,
            contents="Say 'OK' and nothing else",
            config=types.GenerateContentConfig(max_output_tokens=10)
        )
        content = response.text if response.text else ""
        return True, f"Response: {content}"
    except Exception as e:
        return False, str(e)


def test_moonshot(api_key: str, model: str) -> tuple[bool, str]:
    """Test Moonshot API connection."""
    try:
        import requests
        
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }
        data = {
            "model": model,
            "messages": [{"role": "user", "content": "Say 'OK' and nothing else"}],
            "max_tokens": 10
        }
        
        response = requests.post(
            "https://api.moonshot.cn/v1/chat/completions",
            headers=headers,
            json=data,
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            content = result.get("choices", [{}])[0].get("message", {}).get("content", "")
            return True, f"Response: {content}"
        else:
            return False, f"HTTP {response.status_code}: {response.text}"
    except Exception as e:
        return False, str(e)


def main():
    print("=" * 60)
    print("AI Orchestrator - API Connection Test")
    print("=" * 60)
    print()
    
    # Load config
    config = Config.load()
    
    tests = [
        ("OpenAI", config.openai_api_key, config.models.openai_model, test_openai),
        ("Anthropic", config.anthropic_api_key, config.models.anthropic_model, test_anthropic),
        ("Gemini", config.gemini_api_key, config.models.gemini_model, test_gemini),
        ("Moonshot", config.moonshot_api_key, config.models.moonshot_model, test_moonshot),
    ]
    
    results = []
    
    for name, api_key, model, test_func in tests:
        print(f"Testing {name}...")
        print(f"  Model: {model}")
        
        if not api_key:
            print(f"  ❌ SKIPPED - No API key configured")
            results.append((name, None, "No API key"))
            print()
            continue
        
        print(f"  API Key: {api_key[:8]}...{api_key[-4:]}")
        
        success, message = test_func(api_key, model)
        
        if success:
            print(f"  ✅ SUCCESS - {message}")
            results.append((name, True, message))
        else:
            print(f"  ❌ FAILED - {message}")
            results.append((name, False, message))
        print()
    
    # Summary
    print("=" * 60)
    print("Summary")
    print("=" * 60)
    
    passed = sum(1 for _, s, _ in results if s is True)
    failed = sum(1 for _, s, _ in results if s is False)
    skipped = sum(1 for _, s, _ in results if s is None)
    
    print(f"  ✅ Passed: {passed}")
    print(f"  ❌ Failed: {failed}")
    print(f"  ⏭️  Skipped: {skipped}")
    print()
    
    if failed > 0:
        print("Failed tests:")
        for name, success, message in results:
            if success is False:
                print(f"  - {name}: {message}")
        sys.exit(1)
    
    print("All configured APIs are working!")
    return 0


if __name__ == "__main__":
    sys.exit(main())
