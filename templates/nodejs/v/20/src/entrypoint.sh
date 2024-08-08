#!/bin/bash
set -eo pipefail

# Check the runtime environment
if [ "$RUNTIME_ENV" = "lambda" ]; then
  echo "Running in AWS Lambda environment..."
  /lambda-entrypoint.sh "strato_task.handler"
else
  echo "Running in ECS environment..."

  /var/lang/bin/node -e "
    import('./strato_task.mjs').then(({ handler }) => {
      (async () => {
        try {
          const event = JSON.parse('$1');
          await handler(event);
        } catch (error) {
          console.error('Error in handler:', error);
        }
      })();
    }).catch(err => console.error('Error importing module:', err));
  "
fi