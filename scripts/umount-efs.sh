#!/bin/bash
set +e

MOUNT_FOLDER='/mnt/efs'

while [ "$1" != "" ]
do
    case $1 in
        -folder|-f ) shift
                    MOUNT_FOLDER=$1
                    ;;
    esac
    shift
done

sudo umount $MOUNT_FOLDER
sudo pgrep -a -f 'ssh -i' | awk '/-fNL 2049/ { print $1 }' | xargs -r kill -9

