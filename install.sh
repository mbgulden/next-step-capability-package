#!/usr/bin/env bash
set -euo pipefail
# ─────────────────────────────────────────────────────────────────
# Next Step Capability Package — One-Command Installer
# ─────────────────────────────────────────────────────────────────
# Usage:
#   curl -fsSL https://... | bash
#   OR
#   ./install.sh
#
# What this does:
#   1. Clones the MCP server (or uses existing)
#   2. Installs Python dependencies
#   3. Creates a systemd service (or Docker compose)
#   4. Walks you through configuration
# ─────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_INSTALL_DIR="${HOME}/next-step-bot"
MCP_REPO="https://github.com/mbgulden/OpenHumanDesignMCP.git"

# ── Colors ──
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Next Step Capability Package Installer ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""

# ── Step 1: Configuration ──────────────────────────────────────
echo -e "${YELLOW}Step 1/6: Configuration${NC}"
echo ""

read -p "Install directory [${DEFAULT_INSTALL_DIR}]: " INSTALL_DIR
INSTALL_DIR="${INSTALL_DIR:-${DEFAULT_INSTALL_DIR}}"

read -p "Assistant name [Jamie]: " ASSISTANT_NAME
ASSISTANT_NAME="${ASSISTANT_NAME:-Jamie}"

read -sp "Telegram Bot Token (from @BotFather): " TELEGRAM_TOKEN
echo ""
if [ -z "$TELEGRAM_TOKEN" ]; then
    echo -e "${RED}ERROR: Telegram Bot Token is required${NC}"
    exit 1
fi

read -sp "DeepSeek API Key: " DEEPSEEK_KEY
echo ""
if [ -z "$DEEPSEEK_KEY" ]; then
    echo -e "${RED}ERROR: DeepSeek API Key is required${NC}"
    exit 1
fi

read -p "MCP server path (leave empty to clone): " MCP_PATH

# ── Step 2: Install MCP Server ─────────────────────────────────
echo ""
echo -e "${YELLOW}Step 2/6: MCP Server${NC}"

MCP_SRC=""
if [ -n "$MCP_PATH" ]; then
    MCP_SRC="${MCP_PATH}/hd-mcp-server/src"
    echo -e "${GREEN}✓ Using existing MCP server at ${MCP_PATH}${NC}"
else
    MCP_DIR="${INSTALL_DIR}/mcp-server"
    if [ ! -d "$MCP_DIR" ]; then
        echo "Cloning OpenHumanDesignMCP..."
        git clone "$MCP_REPO" "$MCP_DIR"
    else
        echo "MCP server already exists, updating..."
        git -C "$MCP_DIR" pull
    fi
    MCP_SRC="${MCP_DIR}/hd-mcp-server/src"
    # Install MCP deps
    pip install -r "${MCP_DIR}/hd-mcp-server/requirements.txt" 2>/dev/null || true
fi

echo -e "${GREEN}✓ MCP server ready at ${MCP_SRC}${NC}"

# ── Step 3: Copy bot files ─────────────────────────────────────
echo ""
echo -e "${YELLOW}Step 3/6: Installing bot${NC}"

mkdir -p "${INSTALL_DIR}/data"

# Copy the package files
cp "${SCRIPT_DIR}/bot.py" "${INSTALL_DIR}/"
cp "${SCRIPT_DIR}/SOUL.md" "${INSTALL_DIR}/"
cp "${SCRIPT_DIR}/family.json" "${INSTALL_DIR}/" 2>/dev/null || cp "${SCRIPT_DIR}/family.json.template" "${INSTALL_DIR}/family.json"

# Create .env
cat > "${INSTALL_DIR}/.env" <<EOF
TELEGRAM_BOT_TOKEN=${TELEGRAM_TOKEN}
DEEPSEEK_API_KEY=${DEEPSEEK_KEY}
NEXTSTEP_MCP_SRC=${MCP_SRC}
NEXTSTEP_NAME=${ASSISTANT_NAME}
EOF

echo -e "${GREEN}✓ Bot files installed to ${INSTALL_DIR}${NC}"

# ── Step 4: Install Python deps ────────────────────────────────
echo ""
echo -e "${YELLOW}Step 4/6: Python dependencies${NC}"

pip install python-telegram-bot openai 2>/dev/null || pip3 install python-telegram-bot openai
echo -e "${GREEN}✓ Dependencies installed${NC}"

# ── Step 5: Deploy ─────────────────────────────────────────────
echo ""
echo -e "${YELLOW}Step 5/6: Deployment method${NC}"
echo "  1) systemd service (Linux)"
echo "  2) Docker"
echo "  3) Just run now (foreground)"
read -p "Choose [1]: " DEPLOY_CHOICE
DEPLOY_CHOICE="${DEPLOY_CHOICE:-1}"

case "$DEPLOY_CHOICE" in
    1)
        # Systemd
        SERVICE_NAME="next-step-bot"
        cat > "/tmp/${SERVICE_NAME}.service" <<EOF
[Unit]
Description=Next Step Bot (${ASSISTANT_NAME})
After=network.target

[Service]
Type=simple
User=${USER}
WorkingDirectory=${INSTALL_DIR}
EnvironmentFile=${INSTALL_DIR}/.env
ExecStart=$(which python3) ${INSTALL_DIR}/bot.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
        sudo mv "/tmp/${SERVICE_NAME}.service" "/etc/systemd/system/${SERVICE_NAME}.service"
        sudo systemctl daemon-reload
        sudo systemctl enable "${SERVICE_NAME}"
        sudo systemctl start "${SERVICE_NAME}"
        sleep 2
        sudo systemctl status "${SERVICE_NAME}" --no-pager -l
        echo -e "${GREEN}✓ Systemd service installed and running${NC}"
        ;;
    2)
        # Docker
        echo "Building Docker image..."
        docker build -t next-step-bot "${SCRIPT_DIR}"
        echo ""
        echo "Run with:"
        echo "  docker run -d --restart always \\"
        echo "    -e TELEGRAM_BOT_TOKEN=${TELEGRAM_TOKEN} \\"
        echo "    -e DEEPSEEK_API_KEY=${DEEPSEEK_KEY} \\"
        echo "    -e NEXTSTEP_MCP_SRC=/app/mcp-server/src \\"
        echo "    -v ${MCP_SRC%/*}:/app/mcp-server \\"
        echo "    next-step-bot"
        echo ""
        echo -e "${GREEN}✓ Docker image built${NC}"
        ;;
    3)
        echo ""
        echo -e "${CYAN}Starting bot in foreground... (Ctrl+C to stop)${NC}"
        cd "${INSTALL_DIR}"
        TELEGRAM_BOT_TOKEN="${TELEGRAM_TOKEN}" \
        DEEPSEEK_API_KEY="${DEEPSEEK_KEY}" \
        NEXTSTEP_MCP_SRC="${MCP_SRC}" \
        NEXTSTEP_NAME="${ASSISTANT_NAME}" \
        python3 bot.py
        ;;
esac

# ── Step 6: Test ───────────────────────────────────────────────
echo ""
echo -e "${YELLOW}Step 6/6: Verify${NC}"
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ${ASSISTANT_NAME} is ready!                        ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo "  Open Telegram and send a message to your bot."
echo "  Try: 'Hey ${ASSISTANT_NAME}, what can you help me with?'"
echo ""
echo "  View logs:  sudo journalctl -u ${SERVICE_NAME} -f"
echo "  Restart:    sudo systemctl restart ${SERVICE_NAME}"
echo ""
