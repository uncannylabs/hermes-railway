# hermes-railway

Thin Railway deployment wrapper for [Nous Research's Hermes Agent](https://github.com/NousResearch/hermes-agent) — native v0.11.0+ dashboard only, no Workspace, no forks of upstream.

Three processes in one Railway container, sharing the persistent volume mounted at `/root/.hermes`:

- `hermes gateway` — messaging gateway (Telegram, Discord, etc.)
- `hermes dashboard` — admin REST API + web UI (127.0.0.1:9119, loopback only)
- `caddy` — public HTTP + HTTP Basic Auth on `$PORT`, reverse-proxies `/` to the dashboard and serves read-only `/viewer/*` for memories, skills, SOUL.md, and config.yaml

## Files

- `Dockerfile` — Nous's official `hermes-agent:latest` image + tini + Caddy static binary. Python, Hermes, prebuilt dashboard web UI all come from the base image.
- `entrypoint.sh` — Bash supervisor. Bcrypt-hashes `HERMES_PASSWORD` at boot for Caddy, starts gateway + dashboard in background, execs Caddy in foreground.
- `Caddyfile` — Listens on `$PORT`, gates everything behind `basic_auth`, routes `/viewer/*` to file-server paths, reverse-proxies everything else to `127.0.0.1:9119` (dashboard).
- `viewer-index.html` — Minimal landing page for `/viewer/` linking to memory/skills/soul/config.

## Public surface

After deploy, the Railway domain (`hermes.uncannylabs.ai`) serves:

- `/` — native Hermes dashboard (Status, Config, API Keys, Sessions, Logs, Analytics, Cron, Skills)
- `/viewer/` — index page
- `/viewer/memory/` — browse `/root/.hermes/memories/`
- `/viewer/skills/` — browse `/root/.hermes/skills/`
- `/viewer/soul` — `/root/.hermes/SOUL.md`
- `/viewer/config.yaml` — `/root/.hermes/config.yaml`

All gated behind HTTP Basic Auth. Username `hermes`, password = `$HERMES_PASSWORD`.

## Railway setup

- Connect this repo to a Railway service
- Attach persistent volume at `/root/.hermes`
- Generate a public domain targeting port 3000
- Required env vars:
  - `HERMES_HOME=/root/.hermes`
  - `HERMES_PASSWORD=<browser login password>`
  - `TELEGRAM_BOT_TOKEN`, `TELEGRAM_ALLOWED_USERS`, `TELEGRAM_HOME_CHANNEL`
- First boot (one-time): SSH in and run `hermes auth add openai-codex --type oauth --no-browser --timeout 900` to bootstrap Codex OAuth
- Then `hermes config set model.default gpt-5.5-codex` and `hermes config set model.provider openai-codex`

## Upstream update cadence

Every Railway rebuild pulls latest upstream Hermes (`nousresearch/hermes-agent:latest`). Push any commit to this repo's `main` branch or use `railway service redeploy` to trigger a rebuild. No automated poll — add a weekly GitHub Action or n8n cron if desired.
