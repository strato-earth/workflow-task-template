FROM public.ecr.aws/lambda/nodejs:20 AS builder
WORKDIR /build
COPY . .
RUN npm install
RUN npm run format
RUN npm run lint
RUN npm run build
RUN npm run test

FROM public.ecr.aws/lambda/nodejs:20

# Install necessary utilities
RUN dnf install -y unzip && \
    dnf clean all

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws/ && \
    # Remove temporary files to reduce image size
    rm -rf /var/cache/dnf/* /tmp/*

COPY --from=builder /build/dist/strato_task.mjs /var/task/
COPY src/*.sh /var/task/
RUN chmod +x /var/task/*.sh

ENTRYPOINT ["/var/task/entrypoint.sh"]