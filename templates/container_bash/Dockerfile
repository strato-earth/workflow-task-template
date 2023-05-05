FROM ubuntu:latest

WORKDIR /

RUN apt-get update && apt-get -y install zip jq curl

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

WORKDIR /strato-arsi-prepare-output
ENV PATH="/strato-arsi-prepare-output:${PATH}"

COPY entrypoint.sh ./

ENTRYPOINT ["entrypoint.sh"]
