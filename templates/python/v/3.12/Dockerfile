FROM public.ecr.aws/lambda/python:3.12

WORKDIR /var/task

# Install pipenv
RUN pip install --upgrade pip && pip install pipenv

# Copy the Pipfile and Pipfile.lock into the container
COPY Pipfile Pipfile.lock ./

# Install dependencies using pipenv
# Use --deploy to install exact versions specified in Pipfile.lock
# Use --system to install them into the global Python environment
RUN pipenv install --deploy --ignore-pipfile --system

COPY src/ /var/task/
RUN chmod +x /var/task/*.sh

# Set the entrypoint to your custom script
ENTRYPOINT ["/var/task/entrypoint.sh"]
