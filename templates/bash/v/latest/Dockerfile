FROM public.ecr.aws/lambda/provided:al2023

COPY src/ /var/task/
RUN chmod +x /var/task/*.sh

ENTRYPOINT ["/var/task/entrypoint.sh"]
