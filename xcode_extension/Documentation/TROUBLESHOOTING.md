# Troubleshooting Guide

## Common Issues

### Extension Not Appearing in Xcode

**Symptoms:**
- No "AI Orchestrator" menu in Editor menu
- Extension not listed in System Settings

**Solutions:**

1. **Enable in System Settings**
   ```
   System Settings > Privacy & Security > Extensions > Xcode Source Editor
   Enable "AI Orchestrator for Xcode"
   ```

2. **Restart Xcode completely**
   ```bash
   osascript -e 'quit app "Xcode"'
   sleep 2
   open -a Xcode
   ```

3. **Check extension is installed**
   ```bash
   ls ~/Library/Developer/Xcode/Extensions/
   # Should show: AIOrchestratorXcode.appex
   ```

4. **Reinstall extension**
   ```bash
   ./Scripts/uninstall.sh
   ./Scripts/install.sh
   ```

### MCP Server Connection Failed

**Symptoms:**
- "MCP client not initialized" error
- Commands fail with network errors

**Solutions:**

1. **Verify server is running**
   ```bash
   curl http://localhost:3000
   # Should return a response
   ```

2. **Start the MCP server**
   ```bash
   cd /path/to/ai_orchestrator/mcp_server
   ./start.sh
   ```

3. **Check server URL in configuration**
   ```bash
   cat ~/.config/ai-orchestrator/settings.json | grep mcpServerURL
   ```

4. **Test connection**
   ```bash
   ./Scripts/test-connection.sh
   ```

### Commands Timing Out

**Symptoms:**
- Long delays before errors
- "Request timed out" messages

**Solutions:**

1. **Increase timeout**
   ```json
   {
       "connectionTimeout": 60.0
   }
   ```

2. **Check server load**
   - Reduce concurrent requests
   - Try a faster AI model

3. **Check network**
   ```bash
   ping localhost
   ```

### "No fixes available" When Errors Exist

**Symptoms:**
- Fix command reports no issues
- But code clearly has errors

**Solutions:**

1. **Select the problematic code**
   - Don't rely on entire-file analysis
   - Select specific functions/blocks

2. **Check AI model availability**
   - Verify API keys are configured
   - Try a different model

3. **Check logs**
   ```bash
   tail -f ~/.config/ai-orchestrator/logs/*.log
   ```

### Build and Fix Not Working

**Symptoms:**
- Build doesn't trigger
- Errors not captured

**Solutions:**

1. **Ensure project path is configured**
   - Open project in Xcode first
   - Or set `projectPath` in settings

2. **Check Xcode command line tools**
   ```bash
   xcode-select -p
   # Should show: /Applications/Xcode.app/Contents/Developer
   ```

3. **Verify xcodebuild works**
   ```bash
   xcodebuild -version
   ```

### Keyboard Shortcuts Not Working

**Symptoms:**
- Shortcuts don't trigger commands
- Wrong command triggered

**Solutions:**

1. **Check for conflicts**
   - Go to Xcode > Settings > Key Bindings
   - Search for your shortcut

2. **Reassign shortcuts**
   - Remove conflicting shortcuts
   - Assign new ones to AI Orchestrator commands

3. **Use alternative shortcuts**
   - See [SHORTCUTS.md](SHORTCUTS.md)

## Error Messages

### "API key not found"

```bash
# Add key to Keychain
security add-generic-password -a "openai" \
    -s "com.debuggerlab.ai-orchestrator-xcode" \
    -w "your-api-key"
```

### "Invalid response from server"

- Check MCP server logs
- Verify server version compatibility
- Restart MCP server

### "Extension sandboxing prevented operation"

- The extension has limited system access
- Ensure files are in accessible locations
- Check entitlements configuration

## Logs and Diagnostics

### Extension Logs

```bash
# View logs
tail -f ~/.config/ai-orchestrator/logs/xcode-extension-*.log

# View all logs
ls -la ~/.config/ai-orchestrator/logs/
```

### System Logs

```bash
# View extension system logs
log show --predicate 'subsystem == "com.debuggerlab.ai-orchestrator-xcode"' --last 1h
```

### Console.app

1. Open Console.app
2. Filter by "AI Orchestrator"
3. Look for error messages

## Getting Help

### Gather Diagnostic Information

```bash
# System info
sw_vers
xcodebuild -version

# Extension info
ls -la ~/Library/Developer/Xcode/Extensions/

# Configuration
cat ~/.config/ai-orchestrator/settings.json

# Recent logs
tail -100 ~/.config/ai-orchestrator/logs/*.log
```

### Report Issues

1. Gather diagnostic info above
2. Note exact steps to reproduce
3. Include error messages
4. Open an issue on GitHub

## FAQ

**Q: Can I use the extension offline?**
A: No, the extension requires connection to the MCP server.

**Q: Does the extension work with Swift Playgrounds?**
A: No, only with Xcode source editor.

**Q: Can I use my own AI models?**
A: Yes, configure the MCP server to use your preferred models.

**Q: Is my code sent to external servers?**
A: Code is sent to the MCP server which may forward to AI providers.

**Q: How do I update the extension?**
A: Pull latest changes and run `./Scripts/install.sh`.
