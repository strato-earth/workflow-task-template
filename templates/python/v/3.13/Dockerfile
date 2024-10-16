# First stage: build Python and install dependencies
FROM public.ecr.aws/lambda/provided:al2023 AS builder

WORKDIR /app

# Install necessary build tools and dependencies
RUN dnf install -y \
    gcc \
    openssl-devel \
    bzip2-devel \
    libffi-devel \
    zlib-devel \
    make \
    wget \
    tar \
    unzip jq && \
    dnf clean all

# Build Python 3.13 from source with --prefix to install in /opt/python
RUN LATEST_PYTHON_3_13=$(curl -s https://www.python.org/ftp/python/ | grep -oP '3\.13\.\d+' | sort -V | tail -1) && \
    wget https://www.python.org/ftp/python/$LATEST_PYTHON_3_13/Python-$LATEST_PYTHON_3_13.tgz && \
    tar xzf Python-$LATEST_PYTHON_3_13.tgz && \
    cd Python-$LATEST_PYTHON_3_13 && \
    ./configure --enable-optimizations --prefix=/opt/python && \
    make -j$(nproc) && \
    make install && \
    cd .. && \
    rm -rf Python-$LATEST_PYTHON_3_13.tgz Python-$LATEST_PYTHON_3_13

RUN ln -s /opt/python/bin/python3.13 /usr/bin/python && \
    ln -s /opt/python/bin/pip3.13 /usr/bin/pip

ENV PATH="/opt/python/bin:$PATH"

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
FROM public.ecr.aws/lambda/provided:al2023

WORKDIR /var/task

# Install only the necessary runtime dependencies
RUN dnf install -y \
    openssl \
    bzip2-libs \
    libffi \
    zlib \
    wget \
    unzip jq && \
    dnf clean all

# Copy Python installation from /opt/python in the builder stage to the default system locations
COPY --from=builder /opt/python/bin/python3.13 /usr/local/bin/python3.13
COPY --from=builder /opt/python/bin/pip3.13 /usr/local/bin/pip3.13
COPY --from=builder /opt/python/lib /usr/local/lib
COPY --from=builder /opt/python/include /usr/local/include
COPY --from=builder /opt/python/share /usr/local/share

# Create symlinks for python and pip
RUN ln -s /usr/local/bin/python3.13 /usr/bin/python && \
    ln -s /usr/local/bin/pip3.13 /usr/bin/pip

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws/ && \
    rm -rf /var/cache/dnf/* /tmp/*

# Copy application code
COPY src/ /var/task/
RUN chmod +x /var/task/*.sh && mv /var/task/bootstrap.sh /var/runtime/bootstrap

# Set the entrypoint to your custom script
ENTRYPOINT ["/var/task/entrypoint.sh"]
