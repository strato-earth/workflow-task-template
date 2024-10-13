#!/bin/bash

strato_pre_wrapper() { 
    if [ -f "/var/task/pre.sh" ]; then
        source /var/task/pre.sh "$@"
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
  strato_pre_wrapper "${1}"
  
  Rscript /var/task/task.R
  HANDLER_EXIT_CODE=$?

  strato_post_wrapper

  return $HANDLER_EXIT_CODE
}