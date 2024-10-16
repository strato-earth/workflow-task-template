#!/bin/bash

main() {
  # Get the runtime environment variable, default to 'unknown'
  runtimeEnv=${RUNTIME_ENV:-unknown}
  msg="Hello from $runtimeEnv!"
  echo "$msg"

  # Print command-line arguments if any were passed
  if [ "$#" -gt 0 ]; then
    echo "Received the following arguments:"
    for i in "$@"; do
      echo "Argument: $i"
    done
  else
    echo "No arguments were passed."
  fi

  return 0
}

# Call the main function and pass all arguments
main "$@"
