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
  exit
}

REGION='us-west-2'
AWS_PROFILE=''
MOUNT_FOLDER='/mnt/efs'

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
        -key|-k ) shift
                        KEY=$1
                        ;;
        -username|-u ) shift
                        USER_NAME=$1
                        ;;
        -folder|-f ) shift
                        MOUNT_FOLDER=$1
                        ;;
    esac
    shift
done

if [ "$KEY" = "" ]
then
    echo "Key hasn't been specified. Defaults to ~/keys/strato"
    KEY='~/keys/strato'
fi

if [ "$ENVIRONMENT" = "" ] || [ "$PROFILE" = "" ] || [ "$USER_NAME" = "" ]
then
    usage
fi

AWS_REGION="--region $REGION"
EFS_ENDPOINT=$(aws  ${AWS_PROFILE} ${AWS_REGION} ssm get-parameter --name "/strato/${ENVIRONMENT}/config/network/efs_dns_name" --query "Parameter.Value" --output text)
BASTION_IP=$(aws  ${AWS_PROFILE} ${AWS_REGION} ssm get-parameter --name "/strato/${ENVIRONMENT}/config/network/bastion_public_ip" --query "Parameter.Value" --output text)

ssh -i $KEY $USER_NAME@$BASTION_IP -fNL 2049:$EFS_ENDPOINT:2049
sudo mkdir -p $MOUNT_FOLDER
sudo mount -t nfs -o vers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport localhost:/ $MOUNT_FOLDER



