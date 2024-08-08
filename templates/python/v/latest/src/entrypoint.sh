#!/bin/bash
set -eo pipefail

# Check the runtime environment
if [ "$RUNTIME_ENV" = "lambda" ]; then
  echo "Running in AWS Lambda environment..."
  /lambda-entrypoint.sh "strato_task.handler"
else
  echo "Running in ECS environment..."
  python "./strato_task.py" "$@"
fi
