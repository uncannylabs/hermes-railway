#!/bin/bash
# Supervisor for hermes gateway + hermes dashboard + Caddy reverse proxy.
# Any process dying exits the container; Railway restart policy handles recovery.

set -e

HERMES_HOME="${HERMES_HOME:-/root/.hermes}"
mkdir -p "$HERMES_HOME/logs"

if [ -z "$HERMES_PASSWORD" ]; then
  echo "[entrypoint] FATAL: HERMES_PASSWORD unset — refusing to expose dashboard without auth" >&2
  exit 1
fi

# Bcrypt-hash HERMES_PASSWORD for Caddy basic_auth at boot. Hash-only in-memory;
# plaintext never touches disk. Caddy consumes it via {$HERMES_PASSWORD_HASH}.
export HERMES_PASSWORD_HASH
HERMES_PASSWORD_HASH=$(caddy hash-password --plaintext "$HERMES_PASSWORD")
echo "[entrypoint] basic auth configured (username=hermes)"

echo "[entrypoint] Starting hermes gateway..."
hermes gateway >> "$HERMES_HOME/logs/gateway.log" 2>&1 &
GATEWAY_PID=$!
echo "[entrypoint] hermes gateway pid=$GATEWAY_PID"

echo "[entrypoint] Starting hermes dashboard on 127.0.0.1:9119..."
hermes dashboard --host 127.0.0.1 --port 9119 --no-open >> "$HERMES_HOME/logs/dashboard.log" 2>&1 &
DASHBOARD_PID=$!
echo "[entrypoint] hermes dashboard pid=$DASHBOARD_PID"

# Wait up to 30s for dashboard to respond on /api/status (public endpoint — no auth required)
for i in $(seq 1 30); do
  if curl -fs http://127.0.0.1:9119/api/status > /dev/null 2>&1; then
    echo "[entrypoint] dashboard reachable after ${i}s"
    break
  fi
  sleep 1
done

# If gateway died during startup, exit so Railway restarts cleanly
if ! kill -0 "$GATEWAY_PID" 2>/dev/null; then
  echo "[entrypoint] FATAL: hermes gateway exited during startup" >&2
  exit 1
fi

echo "[entrypoint] Starting Caddy on 0.0.0.0:${PORT:-3000}..."
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
