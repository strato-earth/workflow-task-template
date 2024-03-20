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

# Uncomment the following line if you want to kill the processes using the mount /mnt/efs
# sudo lsof /mnt/efs | awk 'NR>1 {print $2}' | xargs -r sudo kill -9
sudo umount -i $MOUNT_FOLDER 
sudo lsof -ti:2049 | xargs -r sudo kill -9


