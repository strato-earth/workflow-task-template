#!/bin/bash
set -eo pipefail

pipenv --rm
pipenv install

ARTIFACT_FILE_NAME=${ARTIFACT_FILE_NAME:-artifact.zip}
ARTIFACT_FILE_PATH=$(pwd)/$ARTIFACT_FILE_NAME

zip $ARTIFACT_FILE_PATH main.py src/*

PACKAGES_FOLDER=$(pipenv run python -c "import site; print(site.getsitepackages()[0])")
pushd $PACKAGES_FOLDER
zip -ur $ARTIFACT_FILE_PATH .
popd