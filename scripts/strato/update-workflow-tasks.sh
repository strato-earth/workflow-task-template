#!/bin/bash
set -eo pipefail

usage ()
{
  echo 'Update Workflow Tasks.'
  echo ''
  echo 'Usage : update-workflow-tasks.sh -e <environment> -p <profile> '
  echo ''
  echo '-environment  | -e <environment>  The Environment name'
  echo '-region       | -r <aws-region>   The target AWS region. Defaults to [us-west-2]'
  echo '-profile      | -p <aws-profile>  Name of the AWS profile'
  exit
}
COMPONENT='workflow-master'
COMPONENT_SANITIZED=$(tr '-' '_'<<< $COMPONENT)
REGION='us-west-2'
BACKEND_PROFILE=''
TERRAFORM_PROFILE=''
AWS_PROFILE=''
MODULE='workflow-master'

while [ "$1" != "" ]
do
    case $1 in
        -environment|-e   ) shift
                        ENVIRONMENT=$1
                        ;;
        -region|-r ) shift
                        REGION=$1
                        ;;
        -profile|-p ) shift
                        PROFILE=$1
                        BACKEND_PROFILE="-backend-config=profile=$1"
                        TERRAFORM_PROFILE="-var=profile=$1"
                        AWS_PROFILE="--profile $1"
                        ;;
    esac
    shift
done

if [ "$ENVIRONMENT" = "" ]
then
    usage
fi

AWS_REGION="--region $REGION"

MODULE_FOLDER="$(dirname "$0")/../../infrastructure/${MODULE}"

pushd $MODULE_FOLDER

aws ${AWS_PROFILE} ${AWS_REGION} ssm get-parameters-by-path --with-decryption --recursive --path "/strato/${ENVIRONMENT}/" --query "Parameters[*].{Name:Name,Value:Value}" > parameters.json
BACKEND_CONFIG_ARGUMENTS=$(jq -r ".[] | select(.Name==\"/strato/${ENVIRONMENT}/config/backend_config_arguments\") | .Value" parameters.json)
MODULE_BACKEND_CONFIG_ARGUMENTS="${BACKEND_CONFIG_ARGUMENTS} -backend-config=key=${MODULE}/terraform.tfstate"
MODULE_BACKEND_CONFIG_ARGUMENTS+=" $BACKEND_PROFILE"

rm -f terraform.tfvars

for VARIABLE in $(jq -r ".variables|keys[]" ssm_variables.json)
do
  VARIABLE_KEY=$(jq -r ".variables.\"${VARIABLE}\"" ssm_variables.json)
  VARIABLE_PATH="/strato/${ENVIRONMENT}/${VARIABLE_KEY}"
  VARIABLE_VALUE=$(jq ".[] | select(.Name==\"${VARIABLE_PATH}\") | .Value" parameters.json)
  if [ "${VARIABLE_VALUE}" != "" ]
  then
    if [[ $VARIABLE_PATH == *_json ]]
    then
      VARIABLE_VALUE=$(echo $VARIABLE_VALUE | jq -r . | tr -d '\n')
    fi  
    echo "$VARIABLE=$VARIABLE_VALUE" >> terraform.tfvars
  fi
done

tofu init -input=false $MODULE_BACKEND_CONFIG_ARGUMENTS -lock=false
tofu apply -input=false -auto-approve  -var="region=$REGION" $TERRAFORM_PROFILE -var="environment=$ENVIRONMENT" -lock=false

popd