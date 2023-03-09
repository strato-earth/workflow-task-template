#!/bin/bash

set -eo pipefail

usage() {
  echo ''
  echo 'Usage : bootstrap-workflow-task.sh -o <organization> -n <repo-name> -t <template-folder> -w <workflow-task-type> -e <environment> -p <aws-profile>'
  echo '-organization       | -o <organization>        Github organization or handle, in which the repo is going to be created '
  echo '-repo-name          | -n <repo-name>           The new repo name '
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
  -organization|-o )
    shift
    GITHUB_ORGANIZATION=$1
    ;;
  -repo-name|-n )
    shift
    REPO_NAME=$1
    ;;
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
  esac
  shift
done

if [[ "${GITHUB_ORGANIZATION}" = "" || "${REPO_NAME}" = "" || "${TEMPLATE_FOLDER}" = "" || "${ENVIRONMENT}" = "" || "${PROFILE}" = "" || "${WORKFLOW_TASK_TYPE}" = "" ]]; then
  usage
fi

REPO_NAME="$(tr '[:upper:]' '[:lower:]' <<< ${REPO_NAME})"

gh repo create ${GITHUB_ORGANIZATION}/${REPO_NAME} --private --template "strato-earth/workflow-task-template"
sleep 1
git clone git@github.com:${GITHUB_ORGANIZATION}/${REPO_NAME}.git

pushd "${REPO_NAME}"

if [[ ! -d templates/$TEMPLATE_FOLDER ]]; then
  echo "Template folder doesn't exists!"
  exit 1
fi
pwd

cp -ar templates/$TEMPLATE_FOLDER/. .

if [[ "${WORKFLOW_TASK_TYPE}" = "container" ]]; then
  scripts/create-ecr-repo.sh -n "${REPO_NAME}" -e "${ENVIRONMENT}" -r $REGION -p ${PROFILE}
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile ${PROFILE} | jq -r '.Account')
ARTIFACTS_BUCKET=$(aws --profile "${PROFILE}" --region "$REGION" ssm get-parameter --name "/strato/${ENVIRONMENT}/config/workflow_task_artifacts_bucket" --query "Parameter.Value" --output text)

scripts/create-github-oidc.sh -o "${GITHUB_ORGANIZATION}" -n "${REPO_NAME}" -e "${ENVIRONMENT}" -r $REGION -p ${PROFILE} -b $ARTIFACTS_BUCKET -w "${WORKFLOW_TASK_TYPE}"

gh secret set -a actions BUILD_ARTIFACTS_AWS_ACCOUNT_ID --body $AWS_ACCOUNT_ID
gh secret set -a actions BUILD_S3_ARTIFACTS_BUCKET --body $ARTIFACTS_BUCKET

rm -rf templates infrastructure scripts/bootstrap-workflow-task.sh scripts/create-ecr-repo.sh scripts/create-github-oidc.sh
sed -r -i "s;executable1;${REPO_NAME};g" $(egrep "executable1" --exclude-dir=node_modules * -r|cut -f1 -d:|sort -u|egrep -v $(basename $0))

git add .
git commit -m "chore: Initial Commit"
git push

mv scripts/pre-commit .git/hooks/

popd