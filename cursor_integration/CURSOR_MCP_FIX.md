# 🔧 Fixing Cursor MCP Integration

This guide helps you diagnose and fix issues when AI Orchestrator MCP tools don't appear in Cursor IDE.

## 📋 Quick Summary

**The most common issue:** The MCP configuration was placed in the wrong location.

**The fix:** Cursor now uses `~/.cursor/mcp.json` (NOT the old `settings.json` or `mcp-settings.json` locations).

---

## 🚀 Quick Fix (Recommended)

### On Your Mac, run these commands:

```bash
# 1. Navigate to the AI Orchestrator directory
cd ~/ai-orchestrator  # or wherever you installed it

# 2. Run the fix script
./cursor_integration/fix_cursor_mcp.sh

# 3. Completely quit and reopen Cursor
```

That's it! The script will:
- ✅ Find your AI Orchestrator installation
- ✅ Create the correct `~/.cursor/mcp.json` configuration
- ✅ Backup any existing configuration
- ✅ Verify the setup

---

## 🔍 Diagnosing Issues

If the quick fix doesn't work, run the diagnostic script:

```bash
cd ~/ai-orchestrator  # or wherever you installed it
./cursor_integration/diagnose_cursor_mcp.sh
```

This will check:
- ✅ Cursor installation and version
- ✅ MCP configuration file location and format
- ✅ AI Orchestrator installation
- ✅ Python environment and packages
- ✅ MCP server functionality

---

## 📝 Manual Fix (If Scripts Don't Work)

### Step 1: Create the MCP Configuration File

Create or edit `~/.cursor/mcp.json`:

```bash
# Create the .cursor directory if it doesn't exist
mkdir -p ~/.cursor

# Create the mcp.json file
nano ~/.cursor/mcp.json
```

### Step 2: Add This Configuration

Paste this content (adjust paths to your installation):

```json
{
  "mcpServers": {
    "ai-orchestrator": {
      "command": "/Users/YOUR_USERNAME/ai-orchestrator/venv/bin/python",
      "args": [
        "-m",
        "mcp_server.server"
      ],
      "cwd": "/Users/YOUR_USERNAME/ai-orchestrator",
      "env": {
        "PYTHONPATH": "/Users/YOUR_USERNAME/ai-orchestrator"
      }
    }
  }
}
```

**Replace `YOUR_USERNAME` with your actual Mac username.**

If you don't have a virtual environment, use system Python:

```json
{
  "mcpServers": {
    "ai-orchestrator": {
      "command": "python3",
      "args": [
        "-m",
        "mcp_server.server"
      ],
      "cwd": "/Users/YOUR_USERNAME/ai-orchestrator",
      "env": {
        "PYTHONPATH": "/Users/YOUR_USERNAME/ai-orchestrator"
      }
    }
  }
}
```

### Step 3: Restart Cursor

1. **Completely quit Cursor** (Cmd+Q, not just close the window)
2. **Reopen Cursor**

---

## ✅ Verifying MCP is Working

### Method 1: Check Settings

1. Open Cursor
2. Press **Cmd+,** to open Settings
3. Go to **Tools & Integrations** (in left sidebar)
4. Look for **MCP Tools** section
5. You should see:
   - **ai-orchestrator** with a **green dot** ✅

### Method 2: Check Chat Panel

1. Press **Cmd+L** to open Chat panel
2. At the top, select **Agent** mode (dropdown menu)
3. Click the **gear icon ⚙️** or **Available Tools**
4. You should see AI Orchestrator tools listed:
   - `orchestrate_task`
   - `analyze_task`
   - `run_project`
   - etc.

### Method 3: Test with a Prompt

In Agent mode, try:

```
Analyze this task: Create a simple Python script
```

Cursor should automatically use the MCP tools to process this.

---

## 📍 Where to Look in Cursor

### Finding MCP Tools Settings

```
Cursor Menu Structure:

Settings (Cmd+,)
├── General
├── Features  
├── Tools & Integrations  ← LOOK HERE
│   ├── Extensions
│   ├── MCP Tools  ← YOUR MCP SERVERS APPEAR HERE
│   │   └── ai-orchestrator (should have green dot)
│   └── ...
└── ...
```

### Using MCP Tools

```
Chat Panel (Cmd+L)
├── Mode Selector (top dropdown)
│   ├── Chat  ← Basic conversation
│   ├── Edit  ← Code editing
│   └── Agent  ← USE THIS FOR MCP TOOLS ✅
├── Available Tools (gear icon)
│   └── ai-orchestrator tools listed here
└── Chat input
```

---

## ❌ Common Issues & Solutions

### Issue 1: "MCP server not found"

**Cause:** The Python path in mcp.json is incorrect.

**Fix:**
```bash
# Find your Python path
which python3

# Use that path in mcp.json
```

### Issue 2: Green dot not appearing

**Cause:** Configuration file syntax error or wrong location.

**Fix:**
```bash
# Validate JSON syntax
python3 -c "import json; json.load(open('$HOME/.cursor/mcp.json'))"

# If it shows an error, fix the JSON syntax
```

### Issue 3: Tools listed but not working

**Cause:** Missing dependencies or API keys.

**Fix:**
```bash
# Check dependencies
cd ~/ai-orchestrator
pip install -r requirements.txt
cd mcp_server
pip install -r requirements.txt

# Check API keys
cat .env  # Ensure OPENAI_API_KEY and ANTHROPIC_API_KEY are set
```

### Issue 4: "Module not found" errors

**Cause:** PYTHONPATH not set correctly.

**Fix:** Ensure your mcp.json includes:
```json
"env": {
  "PYTHONPATH": "/path/to/ai-orchestrator"
}
```

### Issue 5: Old config was in wrong location

**Cause:** Previous versions used different paths.

**Old (wrong) locations:**
- `~/Library/Application Support/Cursor/User/globalStorage/mcp-settings.json`
- `~/Library/Application Support/Cursor/User/settings.json`

**New (correct) location:**
- `~/.cursor/mcp.json` ✅

---

## 🔎 Checking Cursor Logs

If issues persist, check Cursor's MCP logs:

1. Press **Cmd+Shift+P** to open Command Palette
2. Type: `Developer: Show Logs`
3. Select **MCP Logs** from the dropdown
4. Look for error messages

---

## 📂 Configuration File Reference

### Correct Configuration Location

```
~/.cursor/mcp.json
```

This is the ONLY location Cursor reads MCP configuration from.

### Full Example Configuration

```json
{
  "mcpServers": {
    "ai-orchestrator": {
      "command": "/Users/yourname/ai-orchestrator/venv/bin/python",
      "args": [
        "-m",
        "mcp_server.server"
      ],
      "cwd": "/Users/yourname/ai-orchestrator",
      "env": {
        "PYTHONPATH": "/Users/yourname/ai-orchestrator"
      }
    }
  }
}
```

### Configuration Fields Explained

| Field | Description |
|-------|-------------|
| `command` | Path to Python executable |
| `args` | Arguments passed to Python |
| `cwd` | Working directory for the server |
| `env` | Environment variables |

---

## 🆘 Still Not Working?

1. **Run the diagnostic script** to identify specific issues:
   ```bash
   ./cursor_integration/diagnose_cursor_mcp.sh
   ```

2. **Check Cursor version** - MCP requires version 0.40.0 or later

3. **Test the server manually**:
   ```bash
   cd ~/ai-orchestrator
   PYTHONPATH=. python -m mcp_server.server
   ```
   
   You should see the server start without errors.

4. **Verify API keys** are configured:
   ```bash
   grep "API_KEY" ~/ai-orchestrator/.env
   ```

---

## 📚 Related Documentation

- [CURSOR_SETUP.md](./CURSOR_SETUP.md) - Full Cursor integration guide
- [Main README](../README.md) - Project overview
- [TROUBLESHOOTING.md](../TROUBLESHOOTING.md) - General troubleshooting
