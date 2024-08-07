#!/bin/bash
set -eo pipefail

# Check if ./pre.sh exists before sourcing
if [ -f "./pre.sh" ]; then
    source ./pre.sh
else
    echo "pre.sh does not exist, skipping..."
fi

# Source the handler script
source /var/task/strato_task.sh

# Check the runtime environment
if [ "$RUNTIME_ENV" = "lambda" ]; then
  # Lambda environment
  while true; do
    HEADERS=$(mktemp)
    # Get an event. The HTTP request will block until one is received
    EVENT_DATA=$(curl -sS -LD "${HEADERS}" "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/next")

    # Extract request ID by scraping response headers received above
    REQUEST_ID=$(grep -Fi Lambda-Runtime-Aws-Request-Id "${HEADERS}" | tr -d '[:space:]' | cut -d: -f2)

    # Run the handler function
    RESPONSE=$(handler "${EVENT_DATA}")

    # Send the response
    curl -sS "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/${REQUEST_ID}/response" -d "${RESPONSE}"

    # Clean up the temporary headers file
    rm -f "${HEADERS}"
  done
else
  echo "Running in ECS environment..."
  handler "$@"
fi

# Check if ./post.sh exists before sourcing
if [ -f "./post.sh" ]; then
    source ./post.sh
else
    echo "post.sh does not exist, skipping..."
fi