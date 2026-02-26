# Publishing Guide for AI Orchestrator

This guide provides step-by-step instructions for publishing the AI Orchestrator extension to the VS Code Marketplace under the **Debugger Lab** publisher account.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Create a Publisher Account](#2-create-a-publisher-account)
3. [Create a Personal Access Token](#3-create-a-personal-access-token)
4. [Install and Configure vsce](#4-install-and-configure-vsce)
5. [Verify the Extension](#5-verify-the-extension)
6. [Publish to Marketplace](#6-publish-to-marketplace)
7. [Post-Publishing](#7-post-publishing)
8. [Updating the Extension](#8-updating-the-extension)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Prerequisites

Before publishing, ensure you have:

- [x] Node.js v18+ installed
- [x] npm or yarn package manager
- [x] A Microsoft account (for Azure DevOps)
- [x] The extension packaged as `.vsix` file
- [x] All branding assets (icon, README, etc.)

### Current Package Details

| Field | Value |
|-------|-------|
| **Name** | `ai-orchestrator` |
| **Display Name** | AI Orchestrator - Multi-Model AI Assistant |
| **Publisher** | `debugger-lab` |
| **Version** | `1.0.0` |
| **Package File** | `ai-orchestrator-1.0.0.vsix` |

---

## 2. Create a Publisher Account

### Step 2.1: Sign in to Azure DevOps

1. Go to **[Azure DevOps](https://dev.azure.com/)**
2. Click **"Sign in"** with your Microsoft account
3. If you don't have one, click **"Create one!"** to register

### Step 2.2: Create the Publisher

1. Go to **[Visual Studio Marketplace Publisher Management](https://marketplace.visualstudio.com/manage/publishers)**
2. Click **"Create publisher"**
3. Fill in the details:

   | Field | Value |
   |-------|-------|
   | **ID** | `debugger-lab` |
   | **Name** | `Debugger Lab` |
   | **Description** | Developer tools and AI-powered productivity extensions |
   | **Website** | `https://debuggerlab.com` |
   | **Email** | `support@debuggerlab.com` |

4. Click **"Create"**

> ⚠️ **Important**: The Publisher ID must match exactly what's in `package.json`. We're using `debugger-lab`.

---

## 3. Create a Personal Access Token

### Step 3.1: Access Token Settings

1. Go to **[Azure DevOps](https://dev.azure.com/)**
2. Click on your profile icon (top right)
3. Select **"Personal access tokens"**

### Step 3.2: Create New Token

1. Click **"+ New Token"**
2. Configure the token:

   | Setting | Value |
   |---------|-------|
   | **Name** | `VS Code Marketplace Publishing` |
   | **Organization** | Select "All accessible organizations" |
   | **Expiration** | Custom (set to 1 year or your preference) |
   | **Scopes** | Custom defined |

3. Under **Scopes**, click **"Show all scopes"**
4. Find **"Marketplace"** and select:
   - ✅ **Acquire**
   - ✅ **Manage**
   - ✅ **Publish**

5. Click **"Create"**

> 🔐 **IMPORTANT**: Copy and save the token immediately! It won't be shown again.

### Step 3.3: Store the Token Securely

Store the token in an environment variable for convenience:

```bash
# Add to ~/.bashrc or ~/.zshrc
export VSCE_PAT="your-personal-access-token-here"
```

Then reload:
```bash
source ~/.bashrc
```

---

## 4. Install and Configure vsce

### Step 4.1: Install vsce

```bash
# Install globally
npm install -g @vscode/vsce

# Or use npx (no installation required)
npx @vscode/vsce --version
```

### Step 4.2: Login to Your Publisher

```bash
# Using environment variable (recommended)
vsce login debugger-lab

# Or enter token manually when prompted
```

When prompted, paste your Personal Access Token.

### Verify Login

```bash
vsce verify-pat debugger-lab
```

---

## 5. Verify the Extension

Before publishing, run these checks:

### Step 5.1: Validate Package Structure

```bash
cd /home/ubuntu/ai_orchestrator_vscode

# List all files in the package
vsce ls --tree

# Show package info
vsce show
```

### Step 5.2: Check package.json

Ensure all required fields are present:

```bash
cat package.json | jq '{
  name,
  displayName,
  version,
  publisher,
  description,
  icon,
  repository,
  license,
  engines
}'
```

### Step 5.3: Test Installation Locally

```bash
# Package the extension
vsce package

# Install in VS Code
code --install-extension ai-orchestrator-1.0.0.vsix
```

---

## 6. Publish to Marketplace

### Option A: Direct Publishing (Recommended)

```bash
cd /home/ubuntu/ai_orchestrator_vscode

# Publish directly (will prompt for confirmation)
vsce publish

# Or publish with explicit version
vsce publish 1.0.0
```

### Option B: Publish Pre-Packaged VSIX

```bash
# If you already have the .vsix file
vsce publish --packagePath ai-orchestrator-1.0.0.vsix
```

### Option C: Using the Web Interface

1. Go to **[Marketplace Publisher Management](https://marketplace.visualstudio.com/manage/publishers/debugger-lab)**
2. Click **"+ New extension"** → **"VS Code"**
3. Drag and drop `ai-orchestrator-1.0.0.vsix`
4. Click **"Upload"**

### Expected Output

```
Publishing debugger-lab.ai-orchestrator@1.0.0...
 DONE  Published debugger-lab.ai-orchestrator@1.0.0
Your extension URL: https://marketplace.visualstudio.com/items?itemName=debugger-lab.ai-orchestrator
```

---

## 7. Post-Publishing

### Step 7.1: Verify Publication

1. Visit: **https://marketplace.visualstudio.com/items?itemName=debugger-lab.ai-orchestrator**
2. Check that:
   - ✅ Icon displays correctly
   - ✅ README renders properly
   - ✅ All badges/links work
   - ✅ Screenshots (if any) are visible

### Step 7.2: Test Installation from Marketplace

1. Open VS Code
2. Go to Extensions (`Ctrl+Shift+X`)
3. Search for "AI Orchestrator"
4. Click "Install"
5. Verify the extension works correctly

### Step 7.3: Update GitHub Repository (if applicable)

```bash
# Tag the release
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# Create a GitHub Release
# Go to: https://github.com/DebuggerLab/ai-orchestrator-vscode/releases/new
```

---

## 8. Updating the Extension

### Step 8.1: Update Version Number

Edit `package.json`:
```json
{
  "version": "1.0.1"  // or 1.1.0, 2.0.0, etc.
}
```

Follow [Semantic Versioning](https://semver.org/):
- **PATCH** (1.0.1): Bug fixes
- **MINOR** (1.1.0): New features, backward compatible
- **MAJOR** (2.0.0): Breaking changes

### Step 8.2: Update CHANGELOG.md

Add a new section for the version:
```markdown
## [1.0.1] - YYYY-MM-DD

### Fixed
- Description of bug fix

### Added
- Description of new feature
```

### Step 8.3: Publish Update

```bash
# Package and publish in one step
vsce publish patch  # Increments patch version
vsce publish minor  # Increments minor version
vsce publish major  # Increments major version

# Or publish specific version
vsce publish 1.0.1
```

---

## 9. Troubleshooting

### "Error: Invalid publisher name"

Ensure the publisher in `package.json` matches your Azure DevOps publisher ID exactly:
```json
{
  "publisher": "debugger-lab"
}
```

### "Error: Missing required field 'publisher'"

Add the publisher field to `package.json`:
```json
{
  "publisher": "debugger-lab"
}
```

### "Error: A '+publisher' already exists"

The publisher ID is already taken. Choose a different ID.

### "Unauthorized (401)"

Your Personal Access Token may be:
- Expired - Create a new one
- Missing Marketplace scope - Edit token to add Marketplace permissions
- Invalid - Re-create the token

```bash
# Re-login with new token
vsce logout debugger-lab
vsce login debugger-lab
```

### "Extension name already exists"

The extension name is taken. Update `package.json`:
```json
{
  "name": "ai-orchestrator-unique-name"
}
```

### Large Package Size Warning

Optimize by:
1. Adding files to `.vscodeignore`
2. Bundling with webpack/esbuild
3. Removing unnecessary dependencies

```bash
# Check current size
vsce ls --tree
```

---

## Quick Reference Commands

```bash
# Install vsce
npm install -g @vscode/vsce

# Login
vsce login debugger-lab

# Verify token
vsce verify-pat debugger-lab

# Package extension
vsce package

# List package contents
vsce ls --tree

# Publish
vsce publish

# Publish specific version
vsce publish 1.0.1

# Increment and publish
vsce publish patch|minor|major

# Unpublish (use with caution!)
vsce unpublish debugger-lab.ai-orchestrator
```

---

## Useful Links

| Resource | URL |
|----------|-----|
| VS Code Publishing Guide | https://code.visualstudio.com/api/working-with-extensions/publishing-extension |
| Marketplace Publisher Portal | https://marketplace.visualstudio.com/manage |
| Azure DevOps | https://dev.azure.com/ |
| vsce Documentation | https://github.com/microsoft/vscode-vsce |
| Semantic Versioning | https://semver.org/ |

---

## Support

If you encounter issues with publishing:

- 📧 **Email**: support@debuggerlab.com
- 🐛 **GitHub Issues**: https://github.com/DebuggerLab/ai-orchestrator-vscode/issues

---

**© 2026 Debugger Lab** | Made with ❤️
