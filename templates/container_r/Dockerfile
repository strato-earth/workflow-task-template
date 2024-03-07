FROM rocker/r-base:latest

COPY main.R ./
COPY entrypoint.sh ./
COPY scripts/pre.sh ./
COPY scripts/post.sh ./
COPY wrapped-entrypoint.sh ./

ENTRYPOINT ["/wrapped-entrypoint.sh"]
