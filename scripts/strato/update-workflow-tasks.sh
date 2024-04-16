#!/bin/bash

set -eo pipefail

usage() {
  echo ''
  echo 'Usage : update-workflow-tasks.sh -l <code-location> -v <code-version>'
  echo '-code-location          | -l <code-location>    Code Location'
  echo '-code-version           | -v <code-version>     Code Version'
  echo ''
  exit 1
}

REGION='us-west-2'
AWS_PROFILE=''

while [[ "$1" != "" ]]; do
  case $1 in
  -environment|-e   ) shift
    ENVIRONMENT=$1
    ;;
  -region|-r ) shift
    REGION=$1
    ;;
  -profile|-p ) shift
    PROFILE=$1
    AWS_PROFILE="--profile $1"
    ;;  
  --code-location|-l )
    shift
    CODE_LOCATION=$1
    ;;
  --code-version|-v )
    shift
    CODE_VERSION=$1
    ;;
  esac
  shift
done

if [[ "${CODE_LOCATION}" = "" || "${CODE_VERSION}" = ""  ]]; then
  usage
fi

UPDATE_WORKFLOW_TASKS_PAYLOAD=$(jq -n --arg codeLocation "$CODE_LOCATION" --arg codeVersion "$CODE_VERSION" '{codeLocation: $codeLocation, codeVersion: $codeVersion}' | jq -r '@json')
UPDATE_WORKFLOW_TASKS_FUNCTION_NAME=$(aws --region "$REGION" ${AWS_PROFILE} ssm get-parameter --name "/strato/${ENVIRONMENT}/config/workflow_base/update_workflow_task_function_name" --query "Parameter.Value" --output text)

aws lambda invoke --region "$REGION" ${AWS_PROFILE} --function-name $UPDATE_WORKFLOW_TASKS_FUNCTION_NAME --cli-binary-format raw-in-base64-out --payload $UPDATE_WORKFLOW_TASKS_PAYLOAD /dev/null