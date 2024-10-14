#!/bin/bash

source "/var/task/task.sh"

strato_pre_wrapper() { 
    if [ -f "/var/task/pre.sh" ]; then
        source /var/task/pre.sh
    else
        echo "pre.sh does not exist, skipping..."
    fi
}

strato_post_wrapper() { 
    if [ -f "/var/task/post.sh" ]; then
        source /var/task/post.sh
    else
        echo "post.sh does not exist, skipping..."
    fi
}

strato_handler() {
  trap 'strato_post_wrapper' ERR

  echo "$1" > /tmp/strato_env.json
  strato_pre_wrapper

  HANDLER_EXIT_CODE=0
  # Run handler in a subshell to prevent 'exit' from terminating the main script
  (
      handler
  )
  HANDLER_EXIT_CODE=$?

  strato_post_wrapper

  return $HANDLER_EXIT_CODE
}