#!/bin/bash

set -eo pipefail

_error() {
  # Custom Error Handling here
  exit 1
}

trap "_error" ERR 

# Set umask to ensure all newly created files have 777 permissions, so other users or services (like Lambda) can modify them 
umask 000

while [ "$1" != "" ]
do
    case $1 in
        -action|-a   ) shift
                        ACTION=$1
                        ;;
    esac
    shift
done

# if [ "${ACTION}" = "" ]; then
#   echo 'Usage : entrypoint.sh -a <action>'
#   _error
# fi

echo "Done!"