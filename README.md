# 🧠 AI Shell Plugin - AISH

## 🔍 Title & Overview
The **AI Shell Plugin (AISH)** integrates native AI capabilities directly into your terminal shell environment. Use the `@` prefix for natural language AI prompts and `%` for running workspace-specific tasks. It supports multiple AI vendors OpenAI and Gemini. (Grok and Meta TBD) with a consistent interface designed for cross-platform compatibility (macOS, Linux and Unix) and minimal setup. Currently tested with bash shell. 

> **Note:** The Meta vendor is currently a placeholder until API access becomes publicly available. You can configure it now, but actual Meta AI calls are not yet implemented.

> **Note:** Support for Cygwin environments is a WIP

## ✨ Features
- `@` prefix for direct AI natural language prompts  
- `%` prefix for running predefined or custom tasks within a local workspace directory (`AI_WORKSPACE_DIR`)  
- Multi-vendor AI support: OpenAI, Gemini, and Meta (placeholder)  
- Vi-style incremental fuzzy search through AI interaction history using `/`  
- Command replay shortcuts: `!@` replays last AI prompt, `!%` replays last task  
- Configurable system prompts per vendor for personalized AI behavior  
- Secure input sanitization and context gating to prevent unsafe operations  
- Memory context management per workspace with add/view/update capabilities stored in JSON  
- Modular vendor architecture to easily add or update AI backend scripts  
- Agent tasks are sandboxed within workspace with safe eval execution  
- Interactive install script for quick setup and configuration

## 📦 Prerequisites
- Bash 4.0 or newer  
- Utilities: `curl`, `jq`, `sed`  
- Internet connection for remote AI API access  
- API keys for OpenAI and/or Gemini (Meta API key support pending)  

## 📁 File Structure
```plaintext
AISH/
├── ai.sh                   # Main command dispatcher and vendor router
├── agent.sh                # Workspace task execution and management
├── vendors/
│   ├── openai.sh           # OpenAI API integration
│   ├── gemini.sh           # Google Gemini API integration
│   └── meta.sh             # Placeholder for Meta AI integration
├── install.sh              # Interactive installer script
├── ai.1                    # manpage for command usage
├── README.md               # This documentation file
└── utils/
    ├── history.sh          # History management helpers
    ├── security.sh         # Input sanitization and security filters
    └── context.sh          # Context memory handling functions
```

## 🚀 Getting Started
```bash
git clone https://github.com/rabeldable/AISH.git
cd AISH
chmod +x install.sh
./install.sh
```
Follow the interactive prompts to enter API keys and configure your preferred AI vendor and models.

## 🖥️ UI & Controls (Command Prefixes)
- `@` → Send natural language prompt to the configured AI vendor  
  - `@ cmd` — Ask the AI to generate or provide a shell command for a task.  
    - Example: `@ cmd list all running processes on my system`  
    - Example: `@ cmd syntax for ps command that finds all processes with python3 and sends to xargs kill`  
  - `@ explain` — Ask the AI to explain a concept, command, or topic in detail.  
    - Example: `@ explain how the bash trap command works`  
    - Example: `@ explain how to setup disk mirroring`  
    - Example: `@ explain how to add ec2 node with apache to AWS ELB`  

- `%` → Run a predefined or custom command/task within the `AI_WORKSPACE_DIR`  
  - Tab Completion after using % 
  - Example: `% show ACTIVE_AI`  
  - Example: `% set ACTIVE_AI openai`

   **Note:** analyze, backup, deploy, restore, status and summarize are currently experimental  

- `!@` or `!%` → Replay the last AI prompt or last agent task respectively

## 🧩 Implementation Details
- `.ai_conf` stores user configuration, loaded automatically by `ai.sh`  
- Vendor-specific API logic is modularized under `vendors/` for easy extension  
- `utils/` scripts provide core helper functions (history, security, context) (WIP) 
- Agent commands run inside workspace via sanitized `eval` to reduce risks  
- Context memory (conversation or task state) persists per workspace in `context.json` (TBD) 

## 🛠️ Extending & Customization
- Add support for new AI vendors by adding scripts to the `vendors/` directory  
- Customize AI prompt templates and response formatting inside `ai.sh`  
- Define and tune task allowlists, filters, and security policies in `security.sh`  
- Extend context persistence logic or add new memory features in `context.sh`  

## 🧪 Troubleshooting
- Ensure `jq`, `curl`, and `sed` are installed and accessible via your `$PATH`  
- Verify your active AI vendor with `echo $ACTIVE_AI` environment variable  
- Check `~/.ai_history.json` for saved prompt and task history  
- Confirm API keys are correctly set in your `.ai_conf` file  

## ❓ FAQ
**Q: How do I switch between AI vendors?**  
A:  Example: `% set ACTIVE_AI openai`
A:  Example: `% set ACTIVE_AI gemini` 

**Q: Can I sandbox or isolate agent tasks?**  
A: Yes. Customize `agent.sh` to run tasks inside containers, virtualenvs, or restricted shells.

**Q: Which shells are supported?**  
A: Officially Bash. Zsh users can adapt aliases and sourcing in `.zshrc`.

## 🛡️ Usage Rights & Warranty
This plugin is licensed under GPLv2. Use at your own risk. No warranties are provided.

## 📚 References
- [OpenAI API Documentation](https://platform.openai.com/docs)  
- [Google AI / Gemini](https://ai.google.dev)  
- [Meta AI Platform (Upcoming)](https://ai.meta.com)  
