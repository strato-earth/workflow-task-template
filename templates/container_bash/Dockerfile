FROM ubuntu:latest

WORKDIR /

RUN apt-get update && apt-get -y install zip jq curl

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

WORKDIR /executable1
ENV PATH="/executable1:${PATH}"

COPY entrypoint.sh ./
COPY scripts/ ./scripts/

ENTRYPOINT ["scripts/strato/wrapped-entrypoint.sh"]
