# Dev Branch Setup - Summary

## ✅ What Was Done

### Files Modified/Created

| File | Status | Purpose |
|------|--------|---------|
| `quick-dev-setup.sh` | Modified | Now uses placeholder API keys |
| `inject-dev-keys.sh` | Created (local) | Contains real keys, git-ignored |
| `.gitignore` | Updated | Excludes inject-dev-keys.sh |
| `README.dev.md` | Updated | Two-step setup instructions |

### GitHub Push Status

✅ **Successfully pushed to dev branch**
- URL: https://github.com/DebuggerLab/ai-orchestrator/tree/dev
- No secrets in version control

---

## 🚀 How to Use (For Users)

### One-Liner Command
```bash
./quick-dev-setup.sh && ./inject-dev-keys.sh
```

### Step-by-Step
```bash
# 1. Clone and checkout dev
git clone https://github.com/DebuggerLab/ai-orchestrator.git
cd ai-orchestrator
git checkout dev

# 2. Run setup (creates config with placeholders)
./quick-dev-setup.sh

# 3. Inject real keys (you need inject-dev-keys.sh locally)
./inject-dev-keys.sh

# 4. Ready to use!
source venv/bin/activate
ai-orchestrator --help
```

---

## 🔐 How Keys Stay Secure

```
┌─────────────────────────────────────────────────────────────┐
│                    GITHUB (PUBLIC)                          │
│                                                             │
│  quick-dev-setup.sh                                         │
│  ├── OPENAI_API_KEY=YOUR_OPENAI_KEY_HERE      ← Placeholder │
│  ├── ANTHROPIC_API_KEY=YOUR_ANTHROPIC_KEY_HERE              │
│  ├── GEMINI_API_KEY=YOUR_GEMINI_KEY_HERE                    │
│  └── MOONSHOT_API_KEY=YOUR_MOONSHOT_KEY_HERE                │
│                                                             │
│  .gitignore                                                 │
│  └── inject-dev-keys.sh                       ← Excluded    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    LOCAL MACHINE (PRIVATE)                  │
│                                                             │
│  inject-dev-keys.sh                           ← Real keys   │
│  ├── sed replace: YOUR_OPENAI_KEY_HERE → sk-proj-xxx       │
│  ├── sed replace: YOUR_ANTHROPIC_KEY_HERE → sk-ant-xxx     │
│  ├── sed replace: YOUR_GEMINI_KEY_HERE → AIza-xxx          │
│  └── sed replace: YOUR_MOONSHOT_KEY_HERE → sk-xxx          │
│                                                             │
│  ~/.config/ai-orchestrator/config.env         ← Final file │
│  └── Contains actual API keys (chmod 600)                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 inject-dev-keys.sh Location

The `inject-dev-keys.sh` file with real API keys is available locally at:
```
/home/ubuntu/ai_orchestrator/inject-dev-keys.sh
```

This file is **NOT** committed to Git. Share it securely with team members if needed.

---

## 🔑 API Keys Reference

The inject script contains these keys:
- **OpenAI**: `sk-proj-N8qr...B6FMA`
- **Anthropic**: `sk-ant-api03-b-GiSm...wAA`
- **Gemini**: `AIzaSyCVXCLo...vuN0`
- **Moonshot**: `sk-PoGI4yv...JUL6`

---

## ✨ Done!

The dev branch is now ready for secure development. Users can set up their environment without exposing API keys to GitHub.
