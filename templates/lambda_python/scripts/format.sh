#!/bin/bash
set -eo pipefail

pipenv run isort src test test_integration
pipenv run black src && pipenv run black test && pipenv run black test_integration
