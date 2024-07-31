FROM public.ecr.aws/lambda/provided:al2023

COPY scripts/ ./scripts/
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

COPY src/strato_task.sh /var/task/strato_task.sh
RUN chmod +x /var/task/strato_task.sh

# Download AWS Lambda RIE and make it executable
# ADD https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie /usr/local/bin/aws-lambda-rie
# RUN chmod +x /usr/local/bin/aws-lambda-rie
# ENTRYPOINT ["/usr/local/bin/aws-lambda-rie", "/usr/local/bin/entrypoint.sh"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
