#!/bin/bash
# Multi-process supervisor for Hermes gateway + dashboard + Workspace UI.
# Any process dying exits the container; Railway restart policy handles recovery.

set -e

mkdir -p /opt/data/logs

# Compatibility symlink for Workspace: its Node code defaults to
# `path.join(os.homedir(), ".hermes")` for Terminal cwd + Sessions paths.
# Point /root/.hermes at /opt/data so both HERMES_HOME consumers and
# homedir-based consumers resolve to the same volume.
if [ ! -e /root/.hermes ]; then
  ln -s /opt/data /root/.hermes
fi

echo "[entrypoint] Starting hermes gateway..."
hermes gateway >> /opt/data/logs/gateway.log 2>&1 &
GATEWAY_PID=$!
echo "[entrypoint] hermes gateway pid=$GATEWAY_PID"

echo "[entrypoint] Starting hermes dashboard on 127.0.0.1:9119..."
hermes dashboard --host 127.0.0.1 --port 9119 --no-open >> /opt/data/logs/dashboard.log 2>&1 &
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
