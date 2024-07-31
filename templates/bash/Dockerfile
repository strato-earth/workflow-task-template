FROM public.ecr.aws/lambda/provided:al2023

COPY scripts/ /var/task/scripts/
COPY src/strato_task.sh /var/task/strato_task.sh

ENTRYPOINT ["/var/task/scripts/strato/entrypoint.sh"]
