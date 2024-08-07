FROM public.ecr.aws/lambda/provided:al2023

COPY src/ /var/task/
RUN chmod +x /var/task/strato_task.sh
COPY entrypoint.sh /var/task/entrypoint.sh
RUN chmod +x /var/task/entrypoint.sh

ENTRYPOINT ["/var/task/entrypoint.sh"]
