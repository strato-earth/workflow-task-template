#!/bin/bash
set -eo pipefail

pushd "$(dirname "$0")/.."
npm install
popd