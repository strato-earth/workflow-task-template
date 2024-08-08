#!/bin/bash
set -eo pipefail

# Check the runtime environment
if [ "$RUNTIME_ENV" = "lambda" ]; then
  export _HANDLER="strato_task.handler"

  RUNTIME_ENTRYPOINT=/var/runtime/bootstrap
  if [ -z "${AWS_LAMBDA_RUNTIME_API}" ]; then
    echo "Starting Lambda RIE..."
    exec /usr/local/bin/aws-lambda-rie $RUNTIME_ENTRYPOINT
  else
    echo "Running in AWS Lambda environment..."
    exec $RUNTIME_ENTRYPOINT
  fi
else
  echo "Running in ECS environment..."
  /var/lang/bin/node -e "import('./strato_task.mjs').then(({ handler }) => { (async () => { await handler(); })(); }).catch(err => console.error(err));"
fi

