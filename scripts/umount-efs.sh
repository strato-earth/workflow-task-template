#!/bin/bash
set +e

MOUNT_FOLDER='/mnt/efs'

sudo umount $MOUNT_FOLDER
sudo pgrep -a -f 'ssh -i' | awk '/-fNL 2049/ { print $1 }' | xargs -r kill -9

