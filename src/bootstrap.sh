#!/bin/bash
set -eo pipefail

source /var/task/strato_task.sh

while true; do
  HEADERS=$(mktemp)
  # Get an event. The HTTP request will block until one is received
  EVENT_DATA=$(curl -sS -LD "${HEADERS}" "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/next")

  # Extract request ID by scraping response headers received above
  REQUEST_ID=$(grep -Fi Lambda-Runtime-Aws-Request-Id "${HEADERS}" | tr -d '[:space:]' | cut -d: -f2)

  if strato_handler "${EVENT_DATA}"; then
    curl "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/$REQUEST_ID/response"  -d "SUCCESS" > /dev/null 2>&1
  else
    echo "Error: Handler failed for EVENT_DATA: $EVENT_DATA" >&2
    curl "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/$REQUEST_ID/error" -d '{"message": "An error occurred during workflow task."}' --header "Lambda-Runtime-Function-Error-Type: Unhandled" > /dev/null 2>&1
  fi

  rm -f "${HEADERS}"
done