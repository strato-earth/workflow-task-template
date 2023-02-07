#!/bin/bash
set -eo pipefail

pip install pipenv

pipenv shell
pipenv install --dev
exit
