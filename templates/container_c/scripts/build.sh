#!/bin/bash
set -eo pipefail

BUILD_FOLDER="$(dirname "$0")/../build"

mkdir -p $BUILD_FOLDER

pushd "$(dirname "$0")/.."
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --target all --config Release -- -j4
popd
