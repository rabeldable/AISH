# 🧠 AI Shell Plugin - AISH

## 🔍 Title & Overview
The **AI Shell Plugin** adds native AI integration to your terminal. Use `@` for natural language prompts and `%` for workspace tasks. Supports OpenAI, Gemini, and Meta models. Designed for cross-platform compatibility (macOS, Linux, WSL) and minimal setup.

## ✨ Features
- `@` prefix for direct AI interaction  
- `%` prefix for local task execution in a working directory  
- Multi-vendor support: OpenAI, Gemini, Meta  
- Vi-style history search via `/` and replay via `!@` / `!%`  
- Configurable system prompts and response formatting  
- Secure: prompt sanitization, context gating, safe task execution  
- Memory context per workspace (add/view/update)

## 📦 Prerequisites
- Bash 4.0+  
- `curl`, `jq`, `sed`  
- Internet access (for remote AI models)  
- API keys for OpenAI, Gemini, or Meta

## 📁 File Structure
```
ai-shell-plugin/
├── ai.sh                   # Command dispatcher and router
├── agent.sh                # Workspace task execution logic
├── vendors/
│   ├── openai.sh
│   ├── gemini.sh
│   └── meta.sh
├── install.sh              # Interactive installer
├── .ai_conf.example        # Sample configuration file
├── ai.1                    # manpage
├── .gitignore
├── README.md
└── utils/
    ├── history.sh
    ├── security.sh
    └── context.sh
```

## 🚀 Getting Started
```bash
git clone https://github.com/yourname/ai-shell-plugin.git
cd ai-shell-plugin
chmod +x install.sh
./install.sh
```

## 🖥️ UI & Controls (Command Prefixes)
- `@` → Send natural language prompt to configured AI  
- `%` → Run command in `AI_WORKSPACE_DIR`  
- `/term` → Search history  
- `!@` or `!%` → Replay last AI or agent command

## 🧩 Implementation Details
- `.ai_conf` is sourced by `ai.sh`  
- Vendor logic is in `vendors/*.sh`  
- `utils/` provides history/context/security handling  
- Agent commands execute via `eval` in workspace (sanitized)  
- Context memory lives in `context.json` within workspace

## 🛠️ Extending & Customization
- Add new vendors by dropping a script into `vendors/`  
- Customize default behavior in `ai.sh`  
- Define task allowlists/filters in `security.sh`  
- Extend context handling via `context.sh`

## 🧪 Troubleshooting
- Ensure `jq` and `curl` are installed and in `$PATH`  
- Use `echo $ACTIVE_AI` to confirm default vendor  
- Check `~/.ai_history.json` for saved entries

## ❓ FAQ
**Q: How do I switch vendors?**  
A: Edit `.ai_conf` and set `ACTIVE_AI=openai|gemini|meta`

**Q: Can I sandbox agent tasks?**  
A: Yes. Customize `agent.sh` to use `virtualenv`, `docker`, etc.

**Q: What shell is supported?**  
A: Bash. Zsh users can adapt aliases in `.zshrc`

## 🛡️ Usage Rights & Warranty
This plugin is GPLv2. Use at your own risk. No warranty is provided.

## 📚 References
- https://platform.openai.com/docs  
- https://ai.google.dev  
- https://ai.meta.com
