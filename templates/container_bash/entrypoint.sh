#!/bin/bash

set -eo pipefail

_error() {
  # Custom Error Handling here
  exit 1
}

trap "_error" ERR 

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