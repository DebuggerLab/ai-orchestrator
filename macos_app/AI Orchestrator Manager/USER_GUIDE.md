# AI Orchestrator Manager - User Guide

Welcome to AI Orchestrator Manager! This guide will help you get started with setting up and using the AI Orchestrator on your Mac.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Using the Server](#using-the-server)
5. [Dashboard](#dashboard)
6. [Viewing Logs](#viewing-logs)
7. [Menu Bar](#menu-bar)
8. [Troubleshooting](#troubleshooting)

---

## Getting Started

### What is AI Orchestrator?

AI Orchestrator is a system that intelligently routes tasks to different AI models based on their strengths:

- **OpenAI (GPT-4)**: Architecture planning, roadmaps
- **Anthropic (Claude)**: Coding, debugging, implementation
- **Google Gemini**: Research, analysis, testing
- **Moonshot (Kimi)**: Code review, optimization

### System Requirements

Before you begin, ensure your Mac meets these requirements:

- ✅ macOS 13.0 (Ventura) or later
- ✅ Python 3.9 or later
- ✅ Git installed
- ✅ Internet connection

---

## Installation

### First Launch

1. **Open the App**
   - Launch "AI Orchestrator Manager" from your Applications folder
   - Or use Spotlight (Cmd + Space) and search for "AI Orchestrator"

2. **Welcome Screen**
   
   You'll see the welcome screen with:
   - System requirements checklist
   - Installation location picker
   - Install button

3. **Check Requirements**
   
   Click "Check All" to verify your system:
   - 🟢 Green checkmark = Requirement met
   - 🔴 Red X = Requirement not met (needs attention)

4. **Choose Location**
   
   The default installation location is `~/ai_orchestrator`. You can:
   - Keep the default
   - Click "Browse..." to choose a different location

5. **Install**
   
   Click "Install AI Orchestrator" and wait for the process to complete:
   1. Checking requirements
   2. Downloading files
   3. Creating Python environment
   4. Installing dependencies
   5. Configuring environment
   6. Setting up server

---

## Configuration

### Setting Up API Keys

1. **Navigate to Configuration**
   - Click "Configuration" in the sidebar

2. **Enter Your API Keys**

   For each AI provider:
   - Enter your API key in the secure field
   - Click the 👁️ eye icon to show/hide the key
   - Click "Test" to verify the key works

3. **Choose Models**
   
   Select your preferred model for each provider:
   
   | Provider | Recommended Model |
   |----------|-------------------|
   | OpenAI | gpt-4o-mini |
   | Anthropic | claude-3-5-sonnet-20241022 |
   | Google | gemini-2.5-flash |
   | Moonshot | moonshot-v1-8k |

4. **Save Configuration**
   
   Click "Save Configuration" to securely store your keys.

### Getting API Keys

| Provider | How to Get Key |
|----------|----------------|
| OpenAI | [platform.openai.com/api-keys](https://platform.openai.com/api-keys) |
| Anthropic | [console.anthropic.com](https://console.anthropic.com) |
| Google | [aistudio.google.com/apikey](https://aistudio.google.com/apikey) |
| Moonshot | [kimi.moonshot.cn](https://kimi.moonshot.cn) |

---

## Using the Server

### Starting the Server

1. **Go to Server Management**
   - Click "Server" in the sidebar

2. **Start the Server**
   - Click the green "Start Server" button
   - Wait for the status to show "Running"

3. **Verify It's Running**
   - Status card shows "🟢 Running"
   - Port information is displayed

### Stopping the Server

1. Click the red "Stop Server" button
2. Wait for status to show "Stopped"

### Server Configuration

- **Port**: Change the server port (default: 3000)
- **Auto-start**: Enable to start server when you log in

> ⚠️ Stop the server before changing configuration

### Using with Cursor IDE

Once the server is running, configure Cursor IDE:

1. Open Cursor settings
2. Navigate to MCP configuration
3. Add the server:
   ```json
   {
     "ai-orchestrator": {
       "command": "python",
       "args": ["/path/to/mcp_server/server.py"]
     }
   }
   ```

---

## Dashboard

The Dashboard provides an overview of your system:

### Status Cards

- **Server Status**: Running/Stopped indicator
- **Active APIs**: Number of configured API connections
- **Uptime**: How long the server has been running

### API Connections

Shows the status of each AI provider:
- 🟢 Connected
- ⚪ Not configured
- 🔴 Error

### Quick Actions

- **Start/Stop Server**: Quick server control
- **Restart Server**: Stop and start the server
- **View Logs**: Jump to the logs view
- **Configure**: Open configuration settings

### Recent Activity

Shows the latest server activity and log entries.

---

## Viewing Logs

### Log Viewer Features

1. **Real-time Updates**
   - Logs appear as they're generated
   - Auto-scroll keeps you at the latest entries

2. **Filtering**
   - **Search**: Type to filter log messages
   - **Level**: Filter by Debug, Info, Warning, or Error

3. **Log Levels**
   - ⬜ **DEBUG**: Detailed debugging information
   - 🟦 **INFO**: General information
   - 🟧 **WARNING**: Potential issues
   - 🟥 **ERROR**: Errors that occurred

### Log Actions

- **Clear**: Remove all logs from the viewer
- **Export**: Save logs to a text file
- **Refresh**: Reload logs from file

---

## Menu Bar

The menu bar icon provides quick access without opening the full app:

### Menu Bar Icon

- **CPU icon**: Shows server status
- **Filled**: Server is running
- **Outline**: Server is stopped

### Quick Menu

Click the menu bar icon to access:

- ▶️ **Start/Stop Server**: Quick toggle
- 📊 **Open Dashboard**: Show main window
- 📝 **View Logs**: Jump to logs
- ⚙️ **Configuration**: Open settings
- 🔌 **Quit**: Exit the application

---

## Troubleshooting

### Server Won't Start

**Symptoms**: Clicking Start does nothing, or status shows Error

**Solutions**:
1. Check if Python is installed:
   - Open Terminal
   - Run: `python3 --version`
   - Should show Python 3.9 or later

2. Check if port is in use:
   - Open Terminal
   - Run: `lsof -i :3000`
   - If something is using the port, change it in configuration

3. Check the logs for errors

### API Connection Failed

**Symptoms**: Test button shows error, red status indicator

**Solutions**:
1. Verify your API key is correct
2. Check your internet connection
3. Ensure the API service is available
4. Check if you have API credits/quota

### Installation Failed

**Symptoms**: Installation stops with an error

**Solutions**:
1. Ensure Git is installed: `git --version`
2. Check internet connection
3. Try a different installation location
4. Check disk space

### App Won't Open

**Symptoms**: App bounces in dock then closes

**Solutions**:
1. Check macOS version (13.0+ required)
2. Try right-click > Open (for unsigned apps)
3. Check System Preferences > Security & Privacy

### Getting Help

If you're still having issues:

1. **Export logs** and review them
2. **Check documentation** at the GitHub repository
3. **File an issue** on GitHub with:
   - macOS version
   - Python version
   - Error messages
   - Steps to reproduce

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘ + , | Open Settings |
| ⌘ + L | View Logs |
| ⌘ + D | Open Dashboard |
| ⌘ + ⇧ + R | Start/Stop Server |
| ⌘ + Q | Quit App |

---

## Updates

To update the AI Orchestrator:

1. Stop the server if running
2. Go to the installation directory
3. Run: `git pull`
4. Restart the app

---

Thank you for using AI Orchestrator Manager! 🚀
