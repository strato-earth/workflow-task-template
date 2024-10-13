FROM public.ecr.aws/lambda/provided:al2023

# Install necessary utilities
RUN dnf install -y unzip jq && \
    dnf clean all

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws/ && \
    # Remove temporary files to reduce image size
    rm -rf /var/cache/dnf/* /tmp/*
    
COPY src/ /var/task/
RUN chmod +x /var/task/*.sh && mv /var/task/bootstrap.sh /var/runtime/bootstrap

ENTRYPOINT ["/var/task/entrypoint.sh"]
