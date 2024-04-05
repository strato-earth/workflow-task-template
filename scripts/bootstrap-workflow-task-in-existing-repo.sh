#!/bin/bash

set -eo pipefail

usage() {
  echo ''
  echo 'Usage : bootstrap-workflow-task-in-existing-repo.sh -o <organization> -n <repo-name> -t <template-folder> -w <workflow-task-type> -e <environment> -p <aws-profile>'
  echo '-template           | -t <template-folder>     The template folder'
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
  -template|-t)
    shift
    TEMPLATE_FOLDER=$1
    ;;
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
  -github-token|-g ) shift
    GH_TOKEN=$1
    ;;
  esac
  shift
done

if [[ "${ENVIRONMENT}" = "" || "${PROFILE}" = "" || ! ("${WORKFLOW_TASK_TYPE}" == "container" || "${WORKFLOW_TASK_TYPE}" == "function") ]]; then
  usage
fi

read GITHUB_ORGANIZATION REPO_NAME <<< $(git config --get remote.origin.url | awk -F '[/:]' '{gsub(".git$", "", $(NF)); print $(NF-1), $(NF)}')

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile ${PROFILE} | jq -r '.Account')
ARTIFACTS_BUCKET=$(aws --profile "${PROFILE}" --region "$REGION" ssm get-parameter --name "/strato/${ENVIRONMENT}/config/workflow_task_artifacts_bucket" --query "Parameter.Value" --output text)

gh secret set -a actions BUILD_ARTIFACTS_AWS_ACCOUNT_ID --body $AWS_ACCOUNT_ID
gh secret set -a actions BUILD_S3_ARTIFACTS_BUCKET --body $ARTIFACTS_BUCKET
if [[ "${GH_TOKEN}" != "" ]]; then
  gh secret set -a actions GH_TOKEN --body $GH_TOKEN
fi

git clone git@github.com:strato-earth/workflow-task-template.git

pushd workflow-task-template

if [[ "${WORKFLOW_TASK_TYPE}" = "container" ]]; then
  scripts/create-ecr-repo.sh -n "${REPO_NAME}" -e "${ENVIRONMENT}" -r $REGION -p ${PROFILE}
  if [[ "${TEMPLATE_FOLDER}" = "" ]]; then
    TEMPLATE_FOLDER="container_bash"
  fi  
fi

if [[ ! -d templates/$TEMPLATE_FOLDER ]]; then
  echo "Template folder doesn't exists!"
  exit 1
fi

scripts/create-github-oidc.sh -o "${GITHUB_ORGANIZATION}" -n "${REPO_NAME}" -e "${ENVIRONMENT}" -r $REGION -p ${PROFILE} -b $ARTIFACTS_BUCKET -w "${WORKFLOW_TASK_TYPE}"

set +e
sed -r -i "s;executable1;${REPO_NAME};g" $(egrep "executable1" templates/$TEMPLATE_FOLDER/* -r|cut -f1 -d:|sort -u)
sed -i "s/BUILD_ENVIRONMENT/$ENVIRONMENT/g" templates/$TEMPLATE_FOLDER/.github/workflows/build.yml
set -e

popd

mkdir -p .github/workflows
cp workflow-task-template/templates/$TEMPLATE_FOLDER/.github/workflows/build.yml .github/workflows/build.yml
mkdir -p scripts
cp workflow-task-template/scripts/update-workflow-tasks.sh scripts/update-workflow-tasks.sh
cp workflow-task-template/scripts/delete-ecr-repo.sh scripts/delete-ecr-repo.sh
cp workflow-task-template/scripts/delete-github-oidc.sh scripts/delete-github-oidc.sh
cp workflow-task-template/scripts/remove-workflow-task.sh scripts/remove-workflow-task.sh
cp workflow-task-template/scripts/get-wrapper.sh scripts/get-wrapper.sh
cp workflow-task-template/templates/container_bash/wrapped-entrypoint.sh wrapped-entrypoint.sh
echo "# placeholder for pre.sh file added by Strato Workflows CI/CD" > scripts/pre.sh
echo "# placeholder for post.sh file added by Strato Workflows CI/CD" > scripts/post.sh
cp -r workflow-task-template/infrastructure ./
[ -d "workflow-task-template/templates/$TEMPLATE_FOLDER/scripts" ] && cp workflow-task-template/templates/$TEMPLATE_FOLDER/scripts/* scripts/

rm -rf workflow-task-template bootstrap-workflow-task-in-existing-repo.sh

git add .
git commit -m "chore: Add Strato Workflow Task CI/CD"
git push
