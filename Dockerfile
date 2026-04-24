# syntax=docker/dockerfile:1.6
# Railway deployment wrapper for NousResearch/hermes-agent + outsourc-e/hermes-workspace
# Three processes in one container, all sharing /root/.hermes:
#   - hermes gateway         messaging (Telegram, Discord, etc.)
#   - hermes dashboard       admin REST API (127.0.0.1:9119)
#   - hermes-workspace       browser cockpit UI (0.0.0.0:3000, public)
# The wrapper itself contains no Hermes code and no Workspace code.
# Hermes is pip-installed from NousResearch at build time.
# Workspace is copied from the outsourc-e GHCR prebuilt image.
# No fork of either upstream.
#
# $HERMES_HOME is /root/.hermes to match Workspace's hardcoded homedir
# path resolution (some Workspace code paths use HERMES_HOME env var,
# others default to os.homedir() + '/.hermes'). Aligning to /root/.hermes
# means zero symlinks and zero divergence from the canonical layout.

FROM python:3.13-slim

# System deps + Node.js 22 (required by hermes-workspace runtime)
RUN apt-get update \
  && apt-get install -y --no-install-recommends git curl ca-certificates tini gnupg \
  && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
  && apt-get install -y --no-install-recommends nodejs \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Hermes Agent from upstream Nous (messaging = Telegram/Discord/etc; web = fastapi + uvicorn for dashboard)
RUN pip install --no-cache-dir \
    "hermes-agent[messaging,web] @ git+https://github.com/NousResearch/hermes-agent.git"

# Copy prebuilt Workspace from outsourc-e's GHCR image (no build step in our image)
COPY --from=ghcr.io/outsourc-e/hermes-workspace:latest /app /opt/workspace

# Hermes home — /root/.hermes matches Workspace's default (os.homedir()/.hermes)
RUN mkdir -p /root/.hermes/logs

# Multi-process entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV PYTHONUNBUFFERED=1 \
    HERMES_HOME=/root/.hermes \
    NODE_ENV=production \
    PORT=3000 \
    HOST=0.0.0.0

EXPOSE 3000

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/entrypoint.sh"]
