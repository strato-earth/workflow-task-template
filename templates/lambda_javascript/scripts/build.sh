#!/bin/bash
set -eo pipefail

pushd "$(dirname "$0")/.."
ARTIFACT_FILE_NAME=${ARTIFACT_FILE_NAME:-artifact.zip}
ARTIFACT_FILE_PATH=$(pwd)/$ARTIFACT_FILE_NAME
npm run build
zip $ARTIFACT_FILE_PATH dist/*
popd