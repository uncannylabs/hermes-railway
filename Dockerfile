# syntax=docker/dockerfile:1.6
# Railway deployment wrapper for NousResearch/hermes-agent — native v0.11.0 dashboard.
# Single public surface: Caddy on $PORT with HTTP Basic Auth in front of:
#   - /                    → native Hermes dashboard (127.0.0.1:9119)
#   - /viewer/memory/*     → read-only browse of /root/.hermes/memories
#   - /viewer/skills/*     → read-only browse of /root/.hermes/skills
#   - /viewer/soul         → SOUL.md
#   - /viewer/config.yaml  → config.yaml
#
# Processes in one container, all sharing the /root/.hermes volume:
#   - hermes gateway       messaging (Telegram, Discord, etc.)
#   - hermes dashboard     admin REST API + web UI (127.0.0.1:9119, loopback only)
#   - caddy                public HTTP + basic auth (0.0.0.0:$PORT)
#
# No forks. Base image is Nous's official hermes-agent image. Caddy static binary.

FROM nousresearch/hermes-agent:latest

USER root

ARG CADDY_VERSION=2.8.4

# tini (clean PID 1) + Caddy static binary
RUN apt-get update \
  && apt-get install -y --no-install-recommends curl ca-certificates tini \
  && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && curl -fsSL "https://github.com/caddyserver/caddy/releases/download/v${CADDY_VERSION}/caddy_${CADDY_VERSION}_linux_amd64.tar.gz" \
     | tar -xz -C /usr/local/bin caddy \
  && chmod +x /usr/local/bin/caddy

COPY Caddyfile /etc/caddy/Caddyfile
COPY viewer-index.html /etc/caddy/viewer/index.html
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# HERMES_HOME matches the Railway volume mount.
# PATH prepends /opt/hermes/.venv/bin so `hermes` CLI resolves in shells.
ENV PYTHONUNBUFFERED=1 \
    HERMES_HOME=/root/.hermes \
    PATH=/opt/hermes/.venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    PORT=3000

EXPOSE 3000

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/entrypoint.sh"]
