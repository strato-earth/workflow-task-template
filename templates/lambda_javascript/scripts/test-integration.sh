#!/bin/bash
set -eo pipefail

pushd "$(dirname "$0")/../test_integration"
npm run test:integration
popd