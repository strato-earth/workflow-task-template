#!/bin/bash
set -exo pipefail

usage ()
{
  echo 'Copies the wrapper scripts'
  echo ''
  echo 'Usage : get-wrapper-scripts.sh -e <environment> -r <region>'
  echo ''
  echo '-environment | -e <environment> The target strato environment'
  echo '-region      | -r <aws-region>  The target AWS region. Defaults to [us-west-2]'
  echo '-profile     | -p <aws-profile> Name of the AWS profile. Optional'
  exit
}

REGION='us-west-2'
AWS_PROFILE=''

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
                        AWS_PROFILE="--profile $1"

    esac
    shift
done

if [ "$ENVIRONMENT" = "" ]
then
    usage
fi
AWS_REGION="--region $REGION"

WORKFLOW_TASK_ARTIFACTS_BUCKET=$(aws $AWS_PROFILE $AWS_REGION ssm get-parameter --name "/strato/${ENVIRONMENT}/config/workflow_task_artifacts_bucket" --query "Parameter.Value" --output text)

pushd "$(dirname "$0")"

aws $AWS_PROFILE $AWS_REGION s3 cp s3://$WORKFLOW_TASK_ARTIFACTS_BUCKET/strato-workflow-tasks-wrapper/strato-workflow-tasks-wrapper.zip .
unzip -j strato-workflow-tasks-wrapper.zip "src/bash/*" -d .
rm strato-workflow-tasks-wrapper.zip

popd