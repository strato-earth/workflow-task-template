#!/bin/bash
set -eo pipefail

pipenv run pylint src test test_integration
