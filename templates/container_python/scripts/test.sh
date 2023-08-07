#!/bin/bash
set -eo pipefail

"$(dirname "$0")"/test-unit.sh
"$(dirname "$0")"/test-integration.sh