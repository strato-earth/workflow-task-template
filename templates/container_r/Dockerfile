FROM rocker/r-base:latest

COPY main.R ./
COPY entrypoint.sh ./
COPY scripts/ ./scripts/

wrapped-entrypoint.sh

ENTRYPOINT ["/scripts/strato/wrapped-entrypoint.sh"]
