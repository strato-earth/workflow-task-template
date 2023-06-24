#!/bin/bash
set -eo pipefail

pushd "$(dirname "$0")/.." > /dev/null
ARTIFACT_FILE_NAME=${ARTIFACT_FILE_NAME:-artifact.zip}
npm run build
pushd dist > /dev/null
zip -r ../$ARTIFACT_FILE_NAME *
popd > /dev/null
popd > /dev/null