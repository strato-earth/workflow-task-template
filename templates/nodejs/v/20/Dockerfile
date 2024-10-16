FROM public.ecr.aws/lambda/provided:al2023 AS builder

# Install Node.js 20
RUN curl -fsSL https://rpm.nodesource.com/setup_20.x | bash - && \
    dnf install -y nodejs

WORKDIR /build
COPY . .
RUN npm install
RUN npm run format
RUN npm run lint
RUN npm run build
RUN npm run test

FROM public.ecr.aws/lambda/provided:al2023

# Install Node.js 20
RUN curl -fsSL https://rpm.nodesource.com/setup_20.x | bash - && \
    dnf install -y nodejs

# Install necessary utilities
RUN dnf install -y unzip jq && \
    dnf clean all

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws/ && \
    rm -rf /var/cache/dnf/* /tmp/*

COPY --from=builder /build/dist/task.mjs /var/task/
COPY src/*.sh /var/task/
RUN chmod +x /var/task/*.sh && mv /var/task/bootstrap.sh /var/runtime/bootstrap

ENTRYPOINT ["/var/task/entrypoint.sh"]
