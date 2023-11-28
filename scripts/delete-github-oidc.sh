#!/bin/bash
set -eo pipefail

usage ()
{
  echo 'Creates GitHub OIDC trust.'
  echo ''
  echo 'Usage : create-github-oidc.sh -o <organization> -n <repo-name> -b <build-artifacts-bucket> -e <environment> -r <region> -p <profile> '
  echo ''
  echo '-organization           | -o <organization>           Github organization or handle, in which the repo is going to be created'
  echo '-repo-name              | -n <repo-name>              The new repo name'
  echo '-build-artifacts-bucket | -b <build-artifacts-bucket> Build Artifact Bucket'
  echo '-environment            | -e <environment>            The project name used to initialize remote state repositories'
  echo '-region                 | -r <aws-region>             The target AWS region. Defaults to [us-west-2]'
  echo '-profile                | -p <aws-profile>            Name of the AWS profile'
  exit
}

REGION='us-west-2'

while [ "$1" != "" ]
do
    case $1 in
        -organization|-o )
            shift
            GITHUB_ORGANIZATION=$1
            ;;
        -repo-name|-n )
            shift
            REPO_NAME=$1
            ;;
        -build-artifacts-bucket|-b )
            shift
            ARTIFACTS_BUCKET=$1
            ;;
        -workflow-task-type|-w)
            shift
            WORKFLOW_TASK_TYPE=$1
            ;;            
        -environment|-e   ) 
            shift
            ENVIRONMENT=$1
            ;;
        -region|-r )
            shift
            REGION=$1
            ;;
        -profile|-p )
            shift
            PROFILE=$1
            ;;
    esac
    shift
done

if [ "$ENVIRONMENT" = "" ] || [ "$PROFILE" = "" ] || [ "$WORKFLOW_TASK_TYPE" = "" ]
then
    usage
    return 1
fi

STATE_CONFIG_FOLDER="$(dirname "$0")/../infrastructure/github"
OIDC_PROVIDER_ARN=$(aws --profile "${PROFILE}" --region "$REGION" ssm get-parameter --name "/strato/${ENVIRONMENT}/config/github/oidc_provider_arn" --query "Parameter.Value" --output text)
BACKEND_CONFIG_ARGUMENTS=$(aws --profile "${PROFILE}" --region "$REGION" ssm get-parameter --name "/strato/${ENVIRONMENT}/config/backend_config_arguments" --query "Parameter.Value" --output text)
BACKEND_CONFIG_ARGUMENTS+=" -backend-config=profile=$PROFILE"
BACKEND_CONFIG_ARGUMENTS+=" -backend-config=key=github/$GITHUB_ORGANIZATION/$REPO_NAME/terraform.tfstate"

pushd $STATE_CONFIG_FOLDER

rm -rf .terraform

terraform init -input=false $BACKEND_CONFIG_ARGUMENTS
terraform destroy -input=false -auto-approve  -var="region=$REGION" -var="profile=$PROFILE" -var="environment=$ENVIRONMENT" -var="github_organization=$GITHUB_ORGANIZATION" -var="task_type=$WORKFLOW_TASK_TYPE" -var="repo_name=$REPO_NAME" -var="oidc_provider_arn=$OIDC_PROVIDER_ARN" -var="build_artifacts_bucket=$ARTIFACTS_BUCKET"

rm -rf .terraform

popd