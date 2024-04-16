#!/bin/bash
set -eo pipefail

usage ()
{
  echo 'Mounts the EFS from a Strato environment locally.'
  echo ''
  echo 'Usage : mount-efs.sh -e <environment> -r <region> -p <profile> -k <key>'
  echo ''
  echo '-environment | -e <environment> The name of the strato environment'
  echo '-region      | -r <aws-region>  The target AWS region. Defaults to [us-west-2]'
  echo '-profile     | -p <aws-profile> Name of the AWS profile'
  echo '-username    | -u Username to be used for opening the tunnel'
  echo '-key         | -k Private key to be used for opening the tunnel'
  echo '-folder      | -f Mount folder'
  echo '-v           | -f EFS Version'
  exit
}

REGION='us-west-2'
AWS_PROFILE=''
MOUNT_FOLDER='/mnt/efs'
EFS_VERSION='4.1'

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
        -folder|-f ) shift
                        MOUNT_FOLDER=$1
                        ;;
        -efs-version|-v ) shift
                        EFS_VERSION=$1
                        ;;
    esac
    shift
done

if [ "$ENVIRONMENT" = "" ] || [ "$PROFILE" = "" ]
then
    usage
fi

AWS_REGION="--region $REGION"

JSON_PARAMS=$(aws ${AWS_PROFILE} ${AWS_REGION} ssm get-parameters --names "/strato/$ENVIRONMENT/config/strato/ops_instance_id" "/strato/$ENVIRONMENT/config/network/efs_dns_name" --query 'Parameters[*].[Name,Value]' --output json)
EFS_ENDPOINT=$(echo $JSON_PARAMS | jq -r ".[] | select(.[0] == \"/strato/$ENVIRONMENT/config/network/efs_dns_name\") | .[1]")
OPS_INSTANCE_ID=$(echo $JSON_PARAMS | jq -r ".[] | select(.[0] == \"/strato/$ENVIRONMENT/config/strato/ops_instance_id\") | .[1]")

cat /dev/null > nohup.out
nohup aws ${AWS_PROFILE} ${AWS_REGION} ssm start-session --target $OPS_INSTANCE_ID --document-name "AWS-StartPortForwardingSessionToRemoteHost" --parameters "portNumber=[2049],localPortNumber=[2049],host=[$EFS_ENDPOINT]"  &

while ! nc -z localhost 2049; do   
  sleep 1 
done

sudo mkdir -p $MOUNT_FOLDER
sudo mount -t nfs -o vers=$EFS_VERSION,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport localhost:/ $MOUNT_FOLDER



