# hermes-railway

Thin Railway deployment wrapper for [Nous Research's Hermes Agent](https://github.com/NousResearch/hermes-agent) plus the [outsourc-e/hermes-workspace](https://github.com/outsourc-e/hermes-workspace) browser cockpit.

Three processes in one Railway container, all sharing the persistent volume mounted at `/root/.hermes`:

- `hermes gateway` — messaging gateway (Telegram, Discord, Slack, etc.)
- `hermes dashboard` — admin REST API (127.0.0.1:9119, localhost only)
- `hermes-workspace` — browser cockpit UI (0.0.0.0:3000, public via Railway domain)

## Files

- `Dockerfile` — Python 3.13 + Node 22, `pip install`s hermes-agent from NousResearch, `COPY --from=ghcr.io/outsourc-e/hermes-workspace:latest` pulls prebuilt Workspace. No forks of either upstream.
- `entrypoint.sh` — Bash supervisor: starts gateway, starts dashboard, waits for dashboard ready, then execs Workspace Next.js server in the foreground.

## Railway setup

- Connect this repo to a Railway service
- Attach persistent volume at `/root/.hermes` (matches Workspace's homedir-based default paths — no symlinks needed)
- Generate a public domain targeting port 3000 (Workspace login page)
- Required env vars:
  - `HERMES_HOME=/root/.hermes`
  - `TELEGRAM_BOT_TOKEN`, `TELEGRAM_ALLOWED_USERS`, `TELEGRAM_HOME_CHANNEL`
  - `API_SERVER_ENABLED=true`, `API_SERVER_HOST=127.0.0.1`, `API_SERVER_PORT=8642`, `API_SERVER_KEY=<generate strong random>`
  - `HERMES_API_URL=http://127.0.0.1:8642`, `HERMES_API_TOKEN=<same as API_SERVER_KEY>`, `HERMES_DASHBOARD_URL=http://127.0.0.1:9119`
  - `HERMES_PASSWORD=<your browser login password>`
- First boot: SSH in and run `hermes auth add openai-codex --type oauth --no-browser --timeout 900` to bootstrap Codex OAuth (device-code flow)
- Then `hermes config set model.default gpt-5.5-codex` and `hermes config set model.provider openai-codex` (v0.11.0+ has live model discovery via Codex OAuth — picker shows whatever OpenAI has currently exposed)

## Upstream update cadence

Every Railway rebuild pulls latest upstream code (unpinned). To trigger a rebuild, push any commit to this repo's main branch or use `railway service redeploy`. No automated poll — add a weekly GitHub Action or n8n cron later.

Same industry-standard pattern as `uncannylabs/n8n-railway`.
