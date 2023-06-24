#!/bin/bash
set -eo pipefail

pushd "$(dirname "$0")/../test"
npm run test:unit
popd
