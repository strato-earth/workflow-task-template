#!/bin/bash
set -eo pipefail

usage ()
{
  echo 'Connect to the OPS instance'
  echo ''
  echo 'Usage : start-ops-session.sh -e <environment> -r <region>'
  echo ''
  echo '-environment | -e <environment> The name of the strato environment'
  echo '-region      | -r <aws-region>  The target AWS region. Defaults to [us-west-2]'
  echo '-profile     | -p <aws-profile> Name of the AWS profile'
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
                        PROFILE=$1
                        AWS_PROFILE="--profile $1"
                        ;;
    esac
    shift
done

if [ "$ENVIRONMENT" = "" ] || [ "$PROFILE" = "" ]
then
    usage
fi

AWS_REGION="--region $REGION"

aws ${AWS_PROFILE}  ${AWS_REGION} ssm start-session --target $(aws ${AWS_PROFILE} ${AWS_REGION} ssm get-parameter --name /strato/${ENVIRONMENT}/config/strato/ops_instance_id --query "Parameter.Value" --output text)
