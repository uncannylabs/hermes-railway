# hermes-railway

Thin deployment wrapper for running [Nous Research's Hermes Agent](https://github.com/NousResearch/hermes-agent) on Railway.

Pulls `hermes-agent` from upstream via pip on every build. No code changes, no fork of the Hermes source.

## Files

- `Dockerfile` — Python 3.13-slim base, installs `hermes-agent[messaging]` from upstream, runs `hermes gateway`.

## Railway setup

- Connect this repo to a Railway service
- Attach a persistent volume at `/opt/data`
- Set required environment variables:
  - `TELEGRAM_BOT_TOKEN`
  - `TELEGRAM_ALLOWED_USERS`
  - `TELEGRAM_HOME_CHANNEL`
  - `HERMES_HOME=/opt/data`
- First boot: SSH in and run `hermes setup` to bootstrap config.yaml, or seed `/opt/data/auth.json` from an existing OAuth session

Same pattern as `uncannylabs/n8n-railway`.
