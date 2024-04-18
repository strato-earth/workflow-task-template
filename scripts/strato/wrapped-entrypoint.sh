#!/bin/bash
set -eo pipefail

# Check if scripts/strato/pre.sh exists before sourcing
if [ -f "scripts/strato/pre.sh" ]; then
    source scripts/strato/pre.sh
else
    echo "scripts/strato/pre.sh does not exist, skipping..."
fi

source entrypoint.sh

# Check if scripts/strato/post.sh exists before sourcing
if [ -f "scripts/strato/post.sh" ]; then
    source scripts/strato/post.sh
else
    echo "scripts/strato/post.sh does not exist, skipping..."
fi