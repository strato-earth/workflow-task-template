#!/bin/bash
set -eo pipefail

pushd "$(dirname "$0")/../test_integration"
pipenv run python -m unittest
popd