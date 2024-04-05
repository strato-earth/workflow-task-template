#!/bin/bash
set -exo pipefail

"$(dirname "$0")"/format.sh
"$(dirname "$0")"/lint.sh