FROM python:3.11-slim

LABEL org.opencontainers.image.title="Next Step Bot"
LABEL org.opencontainers.image.description="AuDHD Executive Function Telegram Bot with Human Design MCP integration"

# Install system deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python deps
RUN pip install --no-cache-dir \
    python-telegram-bot \
    openai \
    pyswisseph \
    pydantic \
    numpy \
    timezonefinder \
    pytz \
    scipy \
    mcp

# Copy bot files
COPY bot.py /app/
COPY SOUL.md /app/
COPY family.json.template /app/family.json

# Create data directory
RUN mkdir -p /app/data

# Clone MCP server
ARG MCP_REPO=https://github.com/mbgulden/OpenHumanDesignMCP.git
RUN git clone --depth 1 ${MCP_REPO} /app/mcp-server
RUN pip install --no-cache-dir -r /app/mcp-server/hd-mcp-server/requirements.txt

# Expose nothing — bot connects outbound to Telegram API
EXPOSE 0

ENV NEXTSTEP_MCP_SRC=/app/mcp-server/hd-mcp-server/src
ENV NEXTSTEP_DB_PATH=/app/data/next_step.db
ENV NEXTSTEP_NAME=Jamie
ENV NEXTSTEP_PROFILE=next-step

# Required at runtime:
#   TELEGRAM_BOT_TOKEN
#   DEEPSEEK_API_KEY

CMD ["python", "bot.py"]
