FROM python:3.9 
ADD main.py .
#Add other dependencies here
RUN pip install boto3

ENTRYPOINT ["entrypoint.sh"]