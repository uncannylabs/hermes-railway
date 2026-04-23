FROM python:3.13-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends git curl ca-certificates \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir "hermes-agent[messaging] @ git+https://github.com/NousResearch/hermes-agent.git"

RUN mkdir -p /opt/data

ENV PYTHONUNBUFFERED=1 \
    HERMES_HOME=/opt/data

EXPOSE 8080

CMD ["hermes", "gateway"]
