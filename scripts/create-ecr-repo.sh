#!/bin/bash
set -eo pipefail

usage ()
{
  echo 'Creates ECR Repo.'
  echo ''
  echo 'Usage : create-ecr-repo.sh -n <repo-name> -e <environment> -r <region> -p <profile> '
  echo ''
  echo '-repo-name    | -n <repo-name>    The new repo name '
  echo '-environment  | -e <environment>  The project name used to initialize remote state repositories'
  echo '-region       | -r <aws-region>   The target AWS region. Defaults to [us-west-2]'
  echo '-profile      | -p <aws-profile>  Name of the AWS profile'
  exit
}

REGION='us-west-2'

while [ "$1" != "" ]
do
    case $1 in
        -repo-name|-n )
            shift
            REPO_NAME=$1
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

if [ "$ENVIRONMENT" = "" ] || [ "$PROFILE" = "" ]
then
    usage
fi

STATE_CONFIG_FOLDER="$(dirname "$0")/../infrastructure/ecr"
OIDC_PROVIDER_ARN=$(aws --profile "${PROFILE}" --region "$REGION" ssm get-parameter --name "/strato/${ENVIRONMENT}/config/github/oidc_provider_arn" --query "Parameter.Value" --output text)
BACKEND_CONFIG_ARGUMENTS=$(aws --profile "${PROFILE}" --region "$REGION" ssm get-parameter --name "/strato/${ENVIRONMENT}/config/backend_config_arguments" --query "Parameter.Value" --output text)
BACKEND_CONFIG_ARGUMENTS+=" -backend-config=profile=$PROFILE"
BACKEND_CONFIG_ARGUMENTS+=" -backend-config=key=ecr/$REPO_NAME/terraform.tfstate"

pushd $STATE_CONFIG_FOLDER

rm -rf .terraform

terraform init -input=false $BACKEND_CONFIG_ARGUMENTS
terraform apply -input=false -auto-approve  -var="region=$REGION" -var="profile=$PROFILE" -var="environment=$ENVIRONMENT" -var="repo_name=$REPO_NAME"

rm -rf .terraform

popd