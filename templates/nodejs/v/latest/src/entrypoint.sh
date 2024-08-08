#!/bin/bash
set -eo pipefail

# Check the runtime environment
if [ "$RUNTIME_ENV" = "lambda" ]; then
  echo "Running in AWS Lambda environment..."
  /lambda-entrypoint.sh "strato_task.handler"
else
  echo "Running in ECS environment..."
  /var/lang/bin/node -e "import('./strato_task.mjs').then(({ handler }) => { (async () => { await handler(process.argv[1]}))(); }).catch(err => console.error(err));" "$1"
fi

