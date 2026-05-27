# Next Step — AuDHD Executive Function Bot with Human Design

A portable, self-hosted Telegram bot that acts as an externalized executive function
filter. Combines task micro-scoping with Human Design coaching — all through a single
conversational AI that never switches modes.

**Powered by DeepSeek API + OpenHumanDesignMCP**

---

## What It Does

- **"Hide the Mountain"**: Stores your full task list in the background. Shows you
  exactly ONE atomic step at a time. Never overwhelms.
- **Micro-Scoping**: "Fix the auth bug" → "Open src/auth.py. Reply 'done' when you see it."
- **Human Design Aware**: Understands your Type, Strategy, Authority, Profile, Channels,
  and Incarnation Cross. Weaves this into coaching naturally — never uses jargon
  unless you ask.
- **Full Chart Analysis**: Ask Jamie about your chart, transits, life direction,
  or compatibility with family members. She pulls data from the local MCP server
  in a single call for deep, nuanced analysis.
- **Conversation Memory**: Remembers your last 20 exchanges. Picks up where you left off.
- **Family Profiles**: Store birth data for your whole family in `family.json`.
  Ask about relationship dynamics or switch profiles with `/who`.

---

## Quick Start (3 Options)

### Option A: One-Command Installer (Linux with systemd)

```bash
git clone https://github.com/mbgulden/next-step-capability-package.git
cd next-step-capability-package
./install.sh
```

Walks you through setup: bot token, API key, MCP server path.
Creates a systemd service that auto-starts on boot.

### Option B: Docker

```bash
# Build
docker build -t next-step-bot .

# Run (replace tokens)
docker run -d --restart always \
  -e TELEGRAM_BOT_TOKEN="1234567890:ABCdef..." \
  -e DEEPSEEK_API_KEY="sk-..." \
  -v next-step-data:/app/data \
  next-step-bot
```

### Option C: Manual

```bash
# 1. Clone the MCP server
git clone https://github.com/mbgulden/OpenHumanDesignMCP.git

# 2. Install deps
pip install python-telegram-bot openai

# 3. Create .env
cat > .env <<EOF
TELEGRAM_BOT_TOKEN=your-telegram-bot-token
DEEPSEEK_API_KEY=sk-your-deepseek-key
NEXTSTEP_MCP_SRC=$(pwd)/OpenHumanDesignMCP/hd-mcp-server/src
EOF

# 4. Run
python bot.py
```

---

## Using Hermes Agent? Native Profile

If you already run [Hermes Agent](https://github.com/NousResearch/hermes-agent),
you can plug Next Step directly into a Hermes profile:

```bash
# Create a profile from the template
hermes profile create next-step --clone-from orchestator

# Drop in the SOUL.md
cp SOUL.md ~/.hermes/profiles/next-step/SOUL.md

# Add your Telegram token + MCP path to the profile's .env
echo "TELEGRAM_BOT_TOKEN=your-token" >> ~/.hermes/profiles/next-step/.env
echo "NEXTSTEP_MCP_SRC=/path/to/OpenHumanDesignMCP/hd-mcp-server/src" >> ~/.hermes/profiles/next-step/.env
echo "DEEPSEEK_API_KEY=sk-..." >> ~/.hermes/profiles/next-step/.env

# Register the MCP server as a tool in config.yaml:
#   mcp_servers:
#     human-design:
#       command: python
#       args: ["-m", "mcp_server"]

# Install and start the gateway
hermes gateway install next-step
hermes gateway start next-step
```

---

## Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `TELEGRAM_BOT_TOKEN` | **Yes** | — | Bot token from @BotFather |
| `DEEPSEEK_API_KEY` | **Yes** | — | DeepSeek API key |
| `NEXTSTEP_MCP_SRC` | No | `./mcp-server/src` | Path to MCP server source |
| `NEXTSTEP_FAMILY_PATH` | No | `./family.json` | Path to family birth data |
| `NEXTSTEP_DB_PATH` | No | `./data/next_step.db` | SQLite database path |
| `NEXTSTEP_NAME` | No | `Jamie` | Assistant display name |
| `NEXTSTEP_PROFILE` | No | `next-step` | Instance identifier for logs |
| `DEEPSEEK_BASE_URL` | No | `https://api.deepseek.com` | API endpoint |

---

## Multi-Instance (Family / Team)

Run as many isolated bots as you want — each with its own token, memory, and database:

### Docker Compose
```bash
# Set tokens in .env
echo "MICHAEL_TELEGRAM_TOKEN=123:abc" >> .env
echo "BECCA_TELEGRAM_TOKEN=456:def" >> .env
echo "DEEPSEEK_API_KEY=sk-..." >> .env

# Create per-person family files
cp family.json.template family-michael.json
cp family.json.template family-becca.json

# Start both
docker-compose up -d
```

### Systemd
```bash
# Create separate directories
mkdir -p ~/bots/michael ~/bots/becca

# Copy bot files and create .env per instance
# Install as separate systemd services:
#   next-step-michael.service
#   next-step-becca.service
```

---

## Commands

| Command | What it does |
|---|---|
| `/start` | Fresh start, clears history |
| `/help` | Show all commands |
| `/list` | See all pending tasks |
| `/status` | Show current task |
| `/chart` | Generate bodygraph image |
| `/map` | Astrocartography world map |
| `/where [career\|love\|family]` | Best location rankings |
| `/who [profile]` | List or switch family profiles |
| `/relate [name]` | Relationship composite |

Or just talk naturally — Jamie handles everything conversationally.

---

## Architecture

```
┌─────────────────────────────────────────┐
│          Telegram (user's phone)         │
└──────────────────┬──────────────────────┘
                   │ Bot API
                   ▼
┌─────────────────────────────────────────┐
│  bot.py — Unified Conversation Pipeline │
│  ┌───────────────────────────────────┐  │
│  │ SOUL.md → System Prompt           │  │
│  │ + conversation_history (20 turns) │  │
│  │ + Tool Loop ([TOOL:...])          │  │
│  └───────────────┬───────────────────┘  │
│                  │                       │
│     ┌────────────┼────────────┐         │
│     ▼            ▼            ▼         │
│  ┌──────┐  ┌──────────┐  ┌─────────┐   │
│  │Task  │  │ Family   │  │DeepSeek │   │
│  │DB    │  │ JSON     │  │API      │   │
│  └──────┘  └──────────┘  └─────────┘   │
└──────────────────┬──────────────────────┘
                   │ Python import
                   ▼
┌─────────────────────────────────────────┐
│  OpenHumanDesignMCP (local)             │
│  ┌───────────────────────────────────┐  │
│  │ Swiss Ephemeris → 26-body calc    │  │
│  │ Matrix Mapper → Gate/Line/Base    │  │
│  │ Synastry Engine → Composites      │  │
│  │ Transit Engine → Live conditioning│  │
│  │ Astro Cartography → World lines   │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

---

## Portability

- **Zero hardcoded paths**: Everything from environment variables
- **MCP server is its own repo**: `OpenHumanDesignMCP` — installable separately
- **Container-ready**: Dockerfile included
- **Hermes-native option**: Drop SOUL.md + config into any Hermes profile
- **No vendor lock-in**: Uses standard OpenAI-compatible API (DeepSeek, Groq, Together, etc.)

---

## License

MIT — use it, modify it, share it.
