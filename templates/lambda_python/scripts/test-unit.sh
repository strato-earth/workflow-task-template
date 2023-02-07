#!/bin/bash
set -eo pipefail

pushd "$(dirname "$0")/../test"
pipenv run python -m unittest
popd
