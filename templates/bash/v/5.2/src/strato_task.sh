#!/bin/bash
set -eo pipefail

function handler {
  echo "Hello from $RUNTIME_ENV"
  echo "Handling event data: ${1}"
}
