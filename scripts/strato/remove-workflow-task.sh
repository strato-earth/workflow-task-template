#!/bin/bash

set -eo pipefail

usage() {
  echo ''
  echo 'Usage : remove-workflow-task.sh -w <workflow-task-type> -e <environment> -p <aws-profile>'
  echo '-workflow-task-type | -w <workflow-task-type>  Workflow task type. "container" or "function"'
  echo '-environment        | -e <environment>         Strato Environment Name'
  echo '-region             | -r <aws-region>          The target AWS region. Defaults to [us-west-2]'
  echo '-profile            | -p <aws-profile>         Name of the AWS profile'
  echo ''
  exit 1
}

REGION='us-west-2'

while [[ "$1" != "" ]]; do
  case $1 in
  -environment|-e )
    shift
    ENVIRONMENT=$1
    ;;
  -region|-r )
    shift
    REGION=$1
    ;;
  -profile|-p ) shift
    PROFILE=$1
    ;;
  esac
  shift
done

if [[ "${ENVIRONMENT}" = "" || "${PROFILE}" = "" ]]; then
  usage
fi


REPO_INFO=$(gh repo view --json owner,name)
REPO_NAME=$(echo "$REPO_INFO" | jq -r '.name')
GITHUB_ORGANIZATION=$(echo "$REPO_INFO" | jq -r '.owner.login')

rm -rf workflow-task-template
git clone git@github.com:strato-earth/workflow-task-template.git

if aws --profile "${PROFILE}" --region "$REGION" ecr describe-repositories --repository-names "$REPO_NAME" 2>/dev/null; then
  image_digests=$(aws --profile "${PROFILE}" --region "$REGION" ecr describe-images --repository-name ${REPO_NAME} --query 'imageDetails[*].imageDigest' --output json | jq -r '.[]')
  for digest in $image_digests; do
    aws --profile "${PROFILE}" --region "$REGION" ecr batch-delete-image --repository-name ${REPO_NAME} --image-ids imageDigest=$digest
  done

  sleep 3

  WORKFLOW_TASKS_REPOS_SSM_KEY="/strato/${ENVIRONMENT}/config/workflow_tasks_repos"
  EXISTING_WORKFLOW_TASKS=$(aws --profile "${PROFILE}" --region "$REGION" ssm get-parameter --name "$WORKFLOW_TASKS_REPOS_SSM_KEY" --query "Parameter.Value" --output text 2>/dev/null || echo "")
  IFS=',' read -ra TASKS_ARRAY <<< "$EXISTING_WORKFLOW_TASKS"
  for i in "${!TASKS_ARRAY[@]}"; do
    if [[ "${TASKS_ARRAY[i]}" == "$GITHUB_ORGANIZATION/$REPO_NAME" ]]; then
      unset 'TASKS_ARRAY[i]'
    fi
  done
  NEW_WORKFLOW_TASKS=$(IFS=','; echo "${TASKS_ARRAY[*]}")
  aws --profile "${PROFILE}" --region "$REGION" ssm put-parameter --name "$WORKFLOW_TASKS_REPOS_SSM_KEY" --value "$NEW_WORKFLOW_TASKS" --type "String" --overwrite

  workflow-task-template/scripts/strato/update-workflow-tasks.sh -e "${ENVIRONMENT}" -r $REGION -p ${PROFILE}
else
  echo "ECR Repository '$REPO_NAME' does not exist. Skipping deletion step."
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile ${PROFILE} | jq -r '.Account')
ARTIFACTS_BUCKET=$(aws --profile "${PROFILE}" --region "$REGION" ssm get-parameter --name "/strato/${ENVIRONMENT}/config/workflow-master/workflow_task_artifacts_bucket" --query "Parameter.Value" --output text)
aws s3 --profile "${PROFILE}" --region "$REGION" rm --recursive s3://${ARTIFACTS_BUCKET}/container/${REPO_NAME}

rm -rf infrastructure scripts/strato .github/workflows/build.yml workflow-task-template remove-workflow-task.sh

git add .
git commit -m "chore: Detach the repo from Strato Workflows, and leave it as a standalone Github repo."
git push

