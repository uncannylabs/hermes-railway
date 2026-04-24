# syntax=docker/dockerfile:1.6
# Railway deployment wrapper for NousResearch/hermes-agent + outsourc-e/hermes-workspace
# Three processes in one container, all sharing /root/.hermes:
#   - hermes gateway         messaging (Telegram, Discord, etc.)
#   - hermes dashboard       admin REST API + web UI (127.0.0.1:9119)
#   - hermes-workspace       browser cockpit UI (0.0.0.0:3000, public)
# Base image is Nous's official hermes-agent Docker image — has Python,
# hermes-agent[all], AND the prebuilt dashboard web frontend. We add Node
# 22 + outsourc-e/hermes-workspace on top. No fork of either upstream.

FROM nousresearch/hermes-agent:latest

USER root

# Install Node.js 22 (required by hermes-workspace runtime) + tini
RUN apt-get update \
  && apt-get install -y --no-install-recommends curl ca-certificates tini gnupg \
  && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
  && apt-get install -y --no-install-recommends nodejs \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy prebuilt Workspace from outsourc-e's GHCR image
COPY --from=ghcr.io/outsourc-e/hermes-workspace:latest /app /opt/workspace

# Multi-process entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# $HERMES_HOME is /root/.hermes to match Workspace's os.homedir()/.hermes default.
# Railway volume mounts at /root/.hermes — all three processes share that dir.
# PATH prepends /opt/hermes/.venv/bin so `hermes` CLI resolves without having
# to source the venv activation script (Nous's stock entrypoint sources it;
# we bypass that entrypoint with our multi-process supervisor).
ENV PYTHONUNBUFFERED=1 \
    HERMES_HOME=/root/.hermes \
    PATH=/opt/hermes/.venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    NODE_ENV=production \
    PORT=3000 \
    HOST=0.0.0.0

EXPOSE 3000

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/entrypoint.sh"]
