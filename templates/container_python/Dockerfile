FROM python:3.9 
ADD main.py .
#Add other dependencies here
RUN pip install boto3

COPY entrypoint.sh ./
COPY scripts/pre.sh ./
COPY scripts/post.sh ./
COPY wrapped-entrypoint.sh ./

ENTRYPOINT ["/wrapped-entrypoint.sh"]
