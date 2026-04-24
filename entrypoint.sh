#!/bin/bash
# Multi-process supervisor for Hermes gateway + dashboard + Workspace UI.
# Any process dying exits the container; Railway restart policy handles recovery.

set -e

HERMES_HOME="${HERMES_HOME:-/root/.hermes}"
mkdir -p "$HERMES_HOME/logs"

echo "[entrypoint] Starting hermes gateway..."
hermes gateway >> "$HERMES_HOME/logs/gateway.log" 2>&1 &
GATEWAY_PID=$!
echo "[entrypoint] hermes gateway pid=$GATEWAY_PID"

echo "[entrypoint] Starting hermes dashboard on 127.0.0.1:9119..."
hermes dashboard --host 127.0.0.1 --port 9119 --no-open >> "$HERMES_HOME/logs/dashboard.log" 2>&1 &
DASHBOARD_PID=$!
echo "[entrypoint] hermes dashboard pid=$DASHBOARD_PID"

# Wait up to 30s for the dashboard REST API to respond
for i in $(seq 1 30); do
  if curl -fs http://127.0.0.1:9119/ > /dev/null 2>&1; then
    echo "[entrypoint] dashboard reachable after ${i}s"
    break
  fi
  sleep 1
done

# If gateway died during startup, abort so Railway can restart the container cleanly
if ! kill -0 "$GATEWAY_PID" 2>/dev/null; then
  echo "[entrypoint] FATAL: hermes gateway exited during startup" >&2
  exit 1
fi

echo "[entrypoint] Starting hermes-workspace on 0.0.0.0:${PORT:-3000}..."
cd /opt/workspace
exec node --max-old-space-size=2048 server-entry.js
