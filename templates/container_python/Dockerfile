FROM python:3.9 
ADD main.py .
#Add other dependencies here
RUN pip install boto3

COPY entrypoint.sh ./
COPY scripts/ ./scripts/

ENTRYPOINT ["scripts/strato/wrapped-entrypoint.sh"]
