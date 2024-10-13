#!/bin/bash
set -eo pipefail

source /var/task/strato_task.sh

# Check the runtime environment
if [ "$RUNTIME_ENV" = "lambda" ]; then
  echo "Running in AWS Lambda environment..."
  /lambda-entrypoint.sh "strato_task.strato_handler"
else
  echo "Running in ECS environment..."
  strato_handler "$@"
fi
