# First stage: build, test, and lint
FROM public.ecr.aws/lambda/python:3.12 AS builder

WORKDIR /app

# Install pipenv
RUN pip install --upgrade pip && pip install pipenv

# Copy the Pipfile and Pipfile.lock into the container
COPY Pipfile Pipfile.lock ./

# Install all dependencies (including dev) using pipenv
RUN pipenv install --deploy --ignore-pipfile --dev

# Copy the application code and tests
COPY src/ /app/src/
COPY test/ /app/test/
COPY test_integration/ /app/test_integration/

# Set the PYTHONPATH to include the src directory
ENV PYTHONPATH="/app/src"

# Install flake8 for linting
RUN pip install flake8

# Run linting and fail if there are any issues
RUN set -e; flake8 src test test_integration

# Install testing dependencies
RUN pip install unittest-xml-reporting

# Run unit tests with XML output
RUN python -m unittest discover -s test

# Run integration tests
RUN python -m unittest discover -s test_integration

# Second stage: create the final container
FROM public.ecr.aws/lambda/python:3.12

WORKDIR /var/task

# Install necessary utilities
RUN dnf install -y unzip jq && \
    dnf clean all

# Install pipenv
RUN pip install --upgrade pip && pip install pipenv

# Copy the Pipfile and Pipfile.lock into the container
COPY Pipfile Pipfile.lock ./

# Install dependencies using pipenv
# Use --deploy to install exact versions specified in Pipfile.lock
# Use --system to install them into the global Python environment
RUN pipenv install --deploy --ignore-pipfile --system && \
    # Clean up pip cache to reduce image size
    rm -rf /root/.cache/pip

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws/ && \
    # Remove temporary files to reduce image size
    rm -rf /var/cache/dnf/* /tmp/*

# Copy application code
COPY src/ /var/task/
RUN chmod +x /var/task/*.sh

# Set the entrypoint to your custom script
ENTRYPOINT ["/var/task/entrypoint.sh"]
