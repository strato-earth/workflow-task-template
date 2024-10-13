echo "Execute Post Wrapper step"
echo "USE_EFS: $USE_EFS"
echo "STRATO_INSIDE_MAP_STATE: $STRATO_INSIDE_MAP_STATE"
echo "EFS_OUTPUT_FILE_PATH: $EFS_OUTPUT_FILE_PATH"
echo "S3_OUTPUT_FILE_PATH: $S3_OUTPUT_FILE_PATH"

files_found=""
if [[ -d "$EFS_OUTPUT_FILE_PATH" ]]; then
    echo "Listing contents of $EFS_OUTPUT_FILE_PATH directory:"
    ls -R $EFS_OUTPUT_FILE_PATH
    files_found=$(find "$EFS_OUTPUT_FILE_PATH" -mindepth 1 -type f)
fi

files_found_local=""
if [[ -d "/data/output" ]]; then
    echo "Listing contents of /data/output directory:"
    ls -R /data/output
    files_found_local=$(find "/data/output" -mindepth 1 -type f)
fi

if [[ "$STRATO_INSIDE_MAP_STATE" == "true" ]]; then
    if [[ "$USE_EFS" == true ]] && [[ -n "$files_found" ]]; then
        if [[ $EFS_OUTPUT_FILE_PATH =~ ([0-9]+)/([0-9]+)/?$ ]]; then
            INTEGER_PART="${BASH_REMATCH[2]}"
            OUTPUTS_PART="${BASH_REMATCH[1]}"
            BASE_PATH="${EFS_OUTPUT_FILE_PATH}"
            NEW_PATH="${BASE_PATH%/*}"
            PATH_MINUS_OUTPUTS=${NEW_PATH%/outputs_[0-9]*}
            METADATA_PATH="${PATH_MINUS_OUTPUTS}/metadata/outputs_${OUTPUTS_PART}"

            cd "$EFS_OUTPUT_FILE_PATH"
            FILENAMES=$(ls | awk '{print "\"" $0 "\""}' | paste -sd, -)

            if [[ -n $FILENAMES ]]; then
                mkdir -p "$METADATA_PATH"
                echo "[$FILENAMES]" > "${METADATA_PATH}/${INTEGER_PART}_metadata.json"
                if [ "$BASE_PATH" != "$NEW_PATH" ]; then  
                    find "$BASE_PATH" -mindepth 1 -maxdepth 1 -exec mv {} "$NEW_PATH" \;
                fi
            fi 
        fi
    elif [[ -n "$files_found" ]]; then
        if [[ $EFS_OUTPUT_FILE_PATH =~ ([0-9]+)/([0-9]+)/?$ ]]; then
            INTEGER_PART="${BASH_REMATCH[2]}"
            OUTPUTS_PART="${BASH_REMATCH[1]}"
            BASE_PATH="${EFS_OUTPUT_FILE_PATH}"
            NEW_PATH="${BASE_PATH%/*}"
            PATH_MINUS_OUTPUTS=${NEW_PATH%/outputs_[0-9]*}
            METADATA_PATH="${PATH_MINUS_OUTPUTS}/metadata/outputs_${OUTPUTS_PART}"
            cd "$EFS_OUTPUT_FILE_PATH"
            FILENAMES=$(ls | awk '{print "\"" $0 "\""}' | paste -sd, -)

            if [[ -n $FILENAMES ]]; then
                mkdir -p "$METADATA_PATH"
                echo "[$FILENAMES]" > "${METADATA_PATH}/${INTEGER_PART}_metadata.json"
                NEW_S3_PATH="${S3_OUTPUT_FILE_PATH%/*}"
                aws s3 cp $EFS_OUTPUT_FILE_PATH $NEW_S3_PATH ${awsdebug} --quiet --recursive     
            fi
        fi
    elif [[ -n "$files_found_local" ]]; then
        if [[ $S3_OUTPUT_FILE_PATH =~ ([0-9]+)/([0-9]+)/?$ ]]; then
            INTEGER_PART="${BASH_REMATCH[2]}"
            OUTPUTS_PART="${BASH_REMATCH[1]}"
            BASE_PATH="${EFS_OUTPUT_FILE_PATH}"
            NEW_PATH="${BASE_PATH%/*}"
            PATH_MINUS_OUTPUTS=${NEW_PATH%/outputs_[0-9]*}
            METADATA_PATH="${PATH_MINUS_OUTPUTS}/metadata/outputs_${OUTPUTS_PART}"

            cd "/data/output"
            FILENAMES=$(ls | awk '{print "\"" $0 "\""}' | paste -sd, -)
            
            if [[ -n $FILENAMES ]]; then
                mkdir -p "$METADATA_PATH"
                echo "[$FILENAMES]" > "${METADATA_PATH}/${INTEGER_PART}_metadata.json"

                NEW_S3_PATH="${S3_OUTPUT_FILE_PATH%/*}"

                aws s3 cp /data/output $NEW_S3_PATH ${awsdebug} --quiet --recursive
            fi
        else
            aws s3 cp /data/output $S3_OUTPUT_FILE_PATH ${awsdebug} --quiet --recursive     
        fi
    fi
else 
    if [[ -z "$USE_EFS" ]] && [[ -n "$files_found" ]]; then
        echo "aws s3 cp $EFS_OUTPUT_FILE_PATH $S3_OUTPUT_FILE_PATH ${awsdebug} --quiet --recursive"
        aws s3 cp $EFS_OUTPUT_FILE_PATH $S3_OUTPUT_FILE_PATH ${awsdebug} --quiet --recursive
    elif [[ -z "$USE_EFS" ]] && [[ -n "$files_found_local" ]]; then
        echo "aws s3 cp /data/output $S3_OUTPUT_FILE_PATH ${awsdebug} --quiet --recursive"
        aws s3 cp /data/output $S3_OUTPUT_FILE_PATH ${awsdebug} --quiet --recursive
    fi
fi

if [ "$RUNTIME_ENV" == "container" ]; then
    TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)

    if [ -n "$INSTANCE_ID" ]; then
        PAYLOAD="{ \"instanceId\": \"$INSTANCE_ID\" }"
        aws lambda invoke --function-name "strato-${ENVIRONMENT}-terminate-workflow-task-instance" --payload "$(echo -n "$PAYLOAD")" --cli-binary-format raw-in-base64-out /dev/null

        if [ $? -eq 0 ]; then
            echo "Lambda invoke command executed successfully to terminate Instance with ID: $INSTANCE_ID"
        else
            echo "Failed to invoke the Lambda function."
        fi
    else
        echo "Could not retrieve the EC2 instance ID."
    fi
fi
