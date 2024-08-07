#!/bin/bash
set -eo pipefail

# Check if ./pre.sh exists before sourcing
if [ -f "./pre.sh" ]; then
    source ./pre.sh
else
    echo "pre.sh does not exist, skipping..."
fi

# Check the runtime environment
if [ "$RUNTIME_ENV" = "lambda" ]; then
  export _HANDLER="strato_task.handler"  # Adjusted to specify the handler function

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
  node -e "import('./strato_task.mjs').then(({ handler }) => { (async () => { await handler(); })(); }).catch(err => console.error(err));"
fi

# Check if ./post.sh exists before sourcing
if [ -f "./post.sh" ]; then
    source ./post.sh
else
    echo "post.sh does not exist, skipping..."
fi
