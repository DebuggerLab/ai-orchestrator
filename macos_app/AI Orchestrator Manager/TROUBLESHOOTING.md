# Troubleshooting Guide

This guide covers common issues and their solutions.

## Quick Diagnostics

Run these commands in Terminal to quickly diagnose issues:

```bash
# Check Python version
python3 --version

# Check if server port is in use
lsof -i :3000

# Check installation directory
ls -la ~/ai_orchestrator

# Check virtual environment
ls -la ~/ai_orchestrator/venv/bin/python

# View recent logs
tail -100 ~/ai_orchestrator/mcp_server/server.log
```

---

## Installation Issues

### "Python not found" or "Python version too old"

**Problem**: Python 3.9+ is not installed or not in PATH.

**Solution**:
1. Install Python via Homebrew:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   brew install python@3.11
   ```

2. Or download from [python.org](https://www.python.org/downloads/)

3. Verify installation:
   ```bash
   python3 --version
   ```

### "Git not found"

**Problem**: Git is not installed.

**Solution**:
1. Install Xcode Command Line Tools:
   ```bash
   xcode-select --install
   ```

2. Or install via Homebrew:
   ```bash
   brew install git
   ```

### "Permission denied" during installation

**Problem**: Cannot write to the installation directory.

**Solution**:
1. Choose a different location (e.g., Documents folder)
2. Or fix permissions:
   ```bash
   sudo chown -R $(whoami) ~/ai_orchestrator
   ```

### "Clone failed" or "Network error"

**Problem**: Cannot download from GitHub.

**Solution**:
1. Check internet connection
2. Try again later (GitHub might be down)
3. Check if firewall is blocking Git:
   ```bash
   git ls-remote https://github.com/debuggerlab/ai-orchestrator.git
   ```

### "pip install failed"

**Problem**: Python packages failed to install.

**Solution**:
1. Update pip:
   ```bash
   ~/ai_orchestrator/venv/bin/pip install --upgrade pip
   ```

2. Install packages manually:
   ```bash
   cd ~/ai_orchestrator
   source venv/bin/activate
   pip install -r requirements.txt
   ```

3. If specific package fails, try:
   ```bash
   pip install --no-cache-dir <package-name>
   ```

---

## Server Issues

### Server won't start

**Check 1**: Is the script present?
```bash
ls -la ~/ai_orchestrator/mcp_server/server.py
```

**Check 2**: Can Python run it?
```bash
cd ~/ai_orchestrator/mcp_server
../venv/bin/python server.py
```

**Check 3**: Is the port in use?
```bash
lsof -i :3000
# If something is using it, kill it:
kill -9 <PID>
```

### Server crashes immediately

**Problem**: Server starts but crashes right away.

**Solution**:
1. Check for import errors:
   ```bash
   cd ~/ai_orchestrator/mcp_server
   ../venv/bin/python -c "import server"
   ```

2. Check dependencies:
   ```bash
   ../venv/bin/pip check
   ```

3. View error output:
   ```bash
   cat ~/ai_orchestrator/mcp_server/server_error.log
   ```

### Server is slow or unresponsive

**Problem**: Server takes too long to respond.

**Solutions**:
1. Check system resources (Activity Monitor)
2. Restart the server
3. Check network latency to API providers
4. Reduce concurrent requests

### "Address already in use"

**Problem**: Port 3000 is occupied.

**Solution**:
1. Find what's using the port:
   ```bash
   lsof -i :3000
   ```

2. Kill the process:
   ```bash
   kill -9 <PID>
   ```

3. Or change the port in Server settings

---

## API Connection Issues

### "Invalid API key"

**Problem**: API key is not accepted.

**Solutions**:
1. Verify the key is correct (no extra spaces)
2. Check if the key is active in provider's dashboard
3. Regenerate the key if needed

### "Rate limit exceeded"

**Problem**: Too many API requests.

**Solutions**:
1. Wait a few minutes and try again
2. Check your API usage quota
3. Upgrade your API plan if needed

### "Connection refused" or "Timeout"

**Problem**: Cannot connect to API service.

**Solutions**:
1. Check internet connection
2. Check if the API service is up:
   - [OpenAI Status](https://status.openai.com)
   - [Anthropic Status](https://status.anthropic.com)
3. Check if your firewall is blocking the connection

### API test works but server doesn't

**Problem**: Configuration test passes but server can't use APIs.

**Solution**:
1. Ensure .env file is updated:
   ```bash
   cat ~/ai_orchestrator/.env
   ```

2. Restart the server after changing configuration

---

## App Issues

### App won't open

**Problem**: App bounces in dock then closes.

**Solutions**:
1. Check macOS version (13.0+ required)
2. Try right-click > Open
3. Check Console.app for crash logs
4. Reset app preferences:
   ```bash
   defaults delete com.debuggerlab.ai-orchestrator-manager
   ```

### App shows "damaged" warning

**Problem**: macOS blocks unsigned app.

**Solutions**:
1. Right-click the app > Open
2. Or allow in System Settings > Privacy & Security
3. Or remove quarantine:
   ```bash
   xattr -cr "/Applications/AI Orchestrator Manager.app"
   ```

### Keychain access denied

**Problem**: App can't store/retrieve API keys.

**Solutions**:
1. Open Keychain Access app
2. Find "AI Orchestrator Manager" entries
3. Right-click > Get Info > Access Control
4. Add the app to "Always allow access"

### Settings not saving

**Problem**: Configuration changes don't persist.

**Solutions**:
1. Check if ~/Library/Preferences is writable
2. Reset preferences:
   ```bash
   defaults delete com.debuggerlab.ai-orchestrator-manager
   ```
3. Restart the app

---

## Log Issues

### Logs not appearing

**Problem**: Log viewer is empty.

**Solutions**:
1. Click "Refresh" button
2. Check if log file exists:
   ```bash
   ls -la ~/ai_orchestrator/mcp_server/server.log
   ```
3. Start the server (logs only appear when running)

### Log file too large

**Problem**: Log file consuming too much disk space.

**Solution**:
1. Clear logs in the app
2. Or manually:
   ```bash
   echo "" > ~/ai_orchestrator/mcp_server/server.log
   ```

---

## Performance Issues

### High CPU usage

**Problem**: App or server using too much CPU.

**Solutions**:
1. Check Activity Monitor for the culprit
2. Restart the server
3. Reduce logging level to Warning or Error
4. Check for infinite loops in custom code

### High memory usage

**Problem**: Memory consumption keeps growing.

**Solutions**:
1. Restart the server periodically
2. Clear old logs
3. Check for memory leaks (especially with custom extensions)

---

## Getting More Help

### Collect Diagnostic Information

Before asking for help, gather this information:

```bash
# System info
sw_vers
python3 --version
git --version

# Installation check
ls -la ~/ai_orchestrator/

# Recent logs
tail -50 ~/ai_orchestrator/mcp_server/server.log

# Error logs
cat ~/Library/Logs/AIOrchestatorManager.log
```

### Contact Support

1. **GitHub Issues**: [Create an issue](https://github.com/debuggerlab/ai-orchestrator/issues/new) with:
   - macOS version
   - Python version
   - Error messages
   - Steps to reproduce

2. **Include logs**: Export and attach log files

3. **Screenshots**: Include relevant screenshots
