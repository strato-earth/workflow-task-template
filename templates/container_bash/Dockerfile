FROM ubuntu:latest

WORKDIR /
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

RUN apt-get update && apt-get -y install zip jq

WORKDIR /executable1
ENV PATH="/executable1:${PATH}"

COPY entrypoint.sh ./

ENTRYPOINT ["entrypoint.sh"]
