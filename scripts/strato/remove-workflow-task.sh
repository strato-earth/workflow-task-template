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
  -workflow-task-type|-w)
    shift
    WORKFLOW_TASK_TYPE=$1
    ;;
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

if [[ "${ENVIRONMENT}" = "" || "${PROFILE}" = "" || ! ("${WORKFLOW_TASK_TYPE}" == "container" || "${WORKFLOW_TASK_TYPE}" == "function") ]]; then
  usage
fi

pushd "$(dirname "$0")/.." > /dev/null

# Get the repository and organization name using GitHub CLI
REPO_INFO=$(gh repo view --json owner,name)

# Extract the repository name and organization name using jq
REPO_NAME=$(echo "$REPO_INFO" | jq -r '.name')
GITHUB_ORGANIZATION=$(echo "$REPO_INFO" | jq -r '.owner.login')

if [[ "${WORKFLOW_TASK_TYPE}" = "container" ]]; then
  # Check if the ECR repository exists
  if aws --profile "${PROFILE}" --region "$REGION" ecr describe-repositories --repository-names "$REPO_NAME" 2>/dev/null; then
    # List images and extract imageDigests
    image_digests=$(aws --profile "${PROFILE}" --region "$REGION" ecr describe-images --repository-name ${REPO_NAME} --query 'imageDetails[*].imageDigest' --output json | jq -r '.[]')

    # Loop over all imageDigests and delete
    for digest in $image_digests; do
      aws --profile "${PROFILE}" --region "$REGION" ecr batch-delete-image --repository-name ${REPO_NAME} --image-ids imageDigest=$digest
    done

    scripts/delete-ecr-repo.sh -n "${REPO_NAME}" -e "${ENVIRONMENT}" -r $REGION -p ${PROFILE}
  else
      echo "ECR Repository '$REPO_NAME' does not exist. Skipping deletion step."
  fi    
fi



AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile ${PROFILE} | jq -r '.Account')
ARTIFACTS_BUCKET=$(aws --profile "${PROFILE}" --region "$REGION" ssm get-parameter --name "/strato/${ENVIRONMENT}/config/workflow_task_artifacts_bucket" --query "Parameter.Value" --output text)
aws s3 --profile "${PROFILE}" --region "$REGION" rm --recursive s3://${ARTIFACTS_BUCKET}/container/${REPO_NAME}

scripts/delete-github-oidc.sh -o "${GITHUB_ORGANIZATION}" -n "${REPO_NAME}" -e "${ENVIRONMENT}" -r $REGION -p ${PROFILE} -b $ARTIFACTS_BUCKET -w "${WORKFLOW_TASK_TYPE}"

rm -rf infrastructure scripts .github/workflows/build.yml

git add .
git commit -m "chore: Detach the repo from Strato Workflows, and leave it as a standalone Github repo."
git push

popd > /dev/null
