#!/bin/bash
set -eo pipefail

pushd "$(dirname "$0")/../test"
# run unit tests here
popd
