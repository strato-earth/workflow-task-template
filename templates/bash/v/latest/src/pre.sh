#!/bin/bash

NEXT_OUTPUT_PATH=""
NEXT_INPUT_INDEX_PATH=""

find_next_output_path() {
    local base_path=$1
    local i=0
    local found=0
    local highest_index=0  # Track the highest index found

    if [[ "$base_path" =~ s3:// ]]; then

        # Search for higher indexed S3 paths
        while : ; do
            local check_path="${base_path}_${i}"
            
            if aws s3 ls "${check_path}/" | grep -q '.'; then
                highest_index=$i
                found=1
            else
                if [[ $found -eq 1 ]]; then
                    ind=$((highest_index + 1))
                    NEXT_OUTPUT_PATH="${base_path}_${ind}"
                fi
                break
            fi
            if [[ $i -eq 0 ]]; then
                i=1
            else
                ((i++))
            fi
        done

    else
       
        while : ; do
            local check_path="${base_path}_${i}"
            if [[ -e "${check_path}" ]]; then
                highest_index=$i
                found=1
            else
                if [[ $found -eq 1 ]]; then
                    NEXT_OUTPUT_PATH="${base_path}_$((highest_index + 1))"
                fi
                break
            fi
            ((i++))
        done
      
        local new_efs_path="${NEXT_OUTPUT_PATH}"
        mkdir -p "$new_efs_path" && echo "Created new EFS directory: $new_efs_path"
        NEXT_OUTPUT_PATH="$new_efs_path"
        
    fi
}


find_highest_index_path() {
   local base_path=$1
    local i=1
    local found=0
    local highest_index=0  # Track the highest index found


    if [[ "$base_path" =~ s3:// ]]; then
        NEXT_INPUT_INDEX_PATH="$S3_INPUT_FILE_PATH"
        
        # Search for higher indexed S3 paths
        while : ; do
            local check_path="${base_path}_${i}"
            if aws s3 ls "${check_path}/" &>/dev/null; then
                NEXT_INPUT_INDEX_PATH="${check_path}"
                found=1
                highest_index=$i
            else
                break
            fi
            ((i++))
        done

    else
        NEXT_INPUT_INDEX_PATH="$EFS_INPUT_FILE_PATH"
        # Search for higher indexed EFS directories
        while : ; do
            local check_path="${base_path}_${i}"
            if [[ -e "${check_path}" ]]; then
                NEXT_INPUT_INDEX_PATH="${check_path}"
                found=1
                highest_index=$i
            else
                break
            fi
            ((i++))
        done
    fi

}

echo "Start pre script..."

cleaned_data=$(echo $ITEM_DATA | tr -d '\n' | tr -d ' ' | tr -d '\t')
if [[ "$cleaned_data" =~ \"item\":\"([^\"]*)\" ]]; then
    ITEM_DATA="${BASH_REMATCH[1]}"
    if [[ "$cleaned_data" =~ \"index\":([0-9]+) ]]; then
        ITEM_INDEX="${BASH_REMATCH[1]}"
    fi
fi


if [[ "$STRATO_INSIDE_MAP_STATE" != "true" ]]; then
    if [[ -n "$S3_INPUT_FILE_PATH" && "$S3_INPUT_FILE_PATH" == */outputs* ]]; then

        if [[ "$S3_INPUT_FILE_PATH" =~ (.*\/outputs_)[0-9]+$ ]]; then
            modified_path="${BASH_REMATCH[1]}"
            modified_path="${modified_path%_}"
            find_highest_index_path "$modified_path"
        else
            find_highest_index_path "$S3_INPUT_FILE_PATH"
        fi

        S3_INPUT_FILE_PATH="$NEXT_INPUT_INDEX_PATH"
    fi

    if [[ -n "$EFS_INPUT_FILE_PATH" && "$EFS_INPUT_FILE_PATH" == */outputs* ]]; then
        if [[ "$EFS_INPUT_FILE_PATH" =~ (.*\/outputs_)[0-9]+$ ]]; then
            modified_path="${BASH_REMATCH[1]}"
            modified_path="${modified_path%_}"
            find_highest_index_path "$modified_path"
        else
            find_highest_index_path "$EFS_INPUT_FILE_PATH"
        fi

        EFS_INPUT_FILE_PATH="$NEXT_INPUT_INDEX_PATH"
    fi

    if [[ -n "$S3_OUTPUT_FILE_PATH" && "$S3_OUTPUT_FILE_PATH" == */outputs* ]]; then
        s3_output_base="${S3_OUTPUT_FILE_PATH%/*}"
        find_next_output_path "$s3_output_base/outputs"
        highest_output_path="$NEXT_OUTPUT_PATH"
        if [[ -n "$highest_output_path" ]]; then
            S3_OUTPUT_FILE_PATH="$highest_output_path"
        fi
    fi

    if [[ -d "$EFS_OUTPUT_FILE_PATH" && "$EFS_OUTPUT_FILE_PATH" == */outputs* ]]; then
        efs_output_base="${EFS_OUTPUT_FILE_PATH%/*}/outputs"
        find_next_output_path "$efs_output_base"
        highest_output_path="$NEXT_OUTPUT_PATH"
        if [[ -n "$highest_output_path" ]]; then
            EFS_OUTPUT_FILE_PATH="/${highest_output_path}"
        fi
    fi
fi

echo "ITEM DATA: $ITEM_DATA"

config_file_path="/mnt/efs/workflows/${WORKFLOW_NAME}/${WORKFLOW_EXECUTION_ID}/${MAP_PARENT_STATE_NAME}/outputPath.json"

if [[ "$STRATO_INSIDE_MAP_STATE" == "true" ]] &&  [[ -f "$config_file_path" ]]; then


    NEXT_OUTPUT_PATH=$(grep '"outputPath":' $config_file_path | awk -F '"' '{print $4}')
        
    cleaned_data=$(echo $ITEM_DATA | tr -d '\n' | tr -d ' ' | tr -d '\t')

    if [[ -n "$S3_OUTPUT_FILE_PATH" && "$S3_OUTPUT_FILE_PATH" =~ /outputs(_[0-9]+)?/?$ ]]; then

        s3_output_base="${S3_OUTPUT_FILE_PATH%/*}"
        object_key="${s3_output_base#*/}/${NEXT_OUTPUT_PATH}/${ITEM_INDEX}"
        NEW_S3_OUTPUT_PATH="s3:$bucket_name/$object_key"
        highest_output_path="$NEW_S3_OUTPUT_PATH"
        if [[ -n "$highest_output_path" ]]; then
            S3_OUTPUT_FILE_PATH="$highest_output_path"
        fi
    fi

    if [[ -d "$EFS_OUTPUT_FILE_PATH" && "$EFS_OUTPUT_FILE_PATH" =~ /outputs(_[0-9]+)?/?$ ]]; then
        # For EFS, find the current highest outputs path
        efs_output_base="${EFS_OUTPUT_FILE_PATH%/*}"
        highest_output_path="${efs_output_base#*/}/${NEXT_OUTPUT_PATH}/${ITEM_INDEX}"
        if [[ -n "$highest_output_path" ]]; then
            EFS_OUTPUT_FILE_PATH="/${highest_output_path}"
            mkdir -p "$EFS_OUTPUT_FILE_PATH" && echo "Created new EFS directory: $EFS_OUTPUT_FILE_PATH"
        fi
    fi
fi

config_file="/mnt/efs/workflows/$WORKFLOW_NAME/$WORKFLOW_EXECUTION_ID/$STATE_NAME/config.json"

echo "config_file: $config_file"

if [[ "$STRATO_INSIDE_MAP_STATE" == "true" ]]; then
    mkdir -p "/mnt/efs/workflows/$WORKFLOW_NAME/$WORKFLOW_EXECUTION_ID/$STATE_NAME/$ITEM_INDEX" && echo "Created new EFS directory: /mnt/efs/workflows/$WORKFLOW_NAME/$WORKFLOW_EXECUTION_ID/$STATE_NAME/$ITEM_INDEX"
    translated_config_file="/mnt/efs/workflows/$WORKFLOW_NAME/$WORKFLOW_EXECUTION_ID/$STATE_NAME/$ITEM_INDEX/translatedConfig.json"
else
    translated_config_file="/mnt/efs/workflows/$WORKFLOW_NAME/$WORKFLOW_EXECUTION_ID/$STATE_NAME/translatedConfig.json"
fi

echo "translated_config_file: $translated_config_file"

if [[ -f "$config_file" ]]; then 

    echo "current S3_INPUT_FILE_PATH: $S3_INPUT_FILE_PATH"
    echo "Config file found at: $config_file"
    echo "Parsing and modifying config file..."

    temp_file="temp.json"
    cp "$config_file" "$temp_file"
    echo "Temporary file created: $temp_file"

    while IFS=":" read -r key value; do
        original_key=$key
        original_value=$value
        key=$(echo $key | tr -d '"' | sed 's/,$//' | xargs)
        value=$(echo $value | tr -d '"' | sed 's/,$//' | xargs)

        echo "Original key: $original_key"
        echo "Cleaned key: $key"
        echo "Original value: $original_value"
        echo "Cleaned value: $value"

        if [[ -z "$key" || -z "$value" ]]; then
            echo "Skipping due to empty key or value."
            continue
        fi

        if [[ "$key" == "use_efs" ]]; then
            export USE_EFS="$value"
            echo "Detected USE_EFS key, setting USE_EFS to: $USE_EFS"
        fi
        
        updated_value="$value"
        if [[ "$updated_value" =~ (\$[a-zA-Z_][a-zA-Z0-9_]*) ]]; then
            env_var="${BASH_REMATCH[1]}"
            env_var_name="${env_var:1}"

            if [[ -n "${!env_var_name}" ]]; then
                updated_value="${updated_value//"$env_var"/"${!env_var_name}"}"
                echo "Updated value after replacement: $updated_value"
            else
                echo "Warning: Environment variable $env_var_name is not set, keeping original value."
            fi
        fi
        sed -i "s|\"$key\": \"$value\"|\"$key\": \"$updated_value\"|" "$temp_file"
        

    done < <(grep -o '"[^"]*"\s*:\s*"[^"]*"' "$config_file")

    echo "Finished processing all keys."

   

    mv "$temp_file" "$translated_config_file"
    echo "Original config file has been updated."

    if [[ -z "$USE_EFS" ]] && [[ "$STRATO_INSIDE_MAP_STATE" != "true" ]]; then
        echo "aws s3 cp $config_file $WORKFLOW_EXECUTIONS_BUCKET/workflows/$WORKFLOW_NAME/$WORKFLOW_EXECUTION_ID/$STATE_NAME/config.json ${awsdebug} --quiet"
        aws s3 cp $config_file $WORKFLOW_EXECUTIONS_BUCKET/workflows/$WORKFLOW_NAME/$WORKFLOW_EXECUTION_ID/$STATE_NAME/config.json ${awsdebug} --quiet
        echo "aws s3 cp $translated_config_file $WORKFLOW_EXECUTIONS_BUCKET/workflows/$WORKFLOW_NAME/$WORKFLOW_EXECUTION_ID/$STATE_NAME/translatedConfig.json ${awsdebug} --quiet"
        aws s3 cp $translated_config_file $WORKFLOW_EXECUTIONS_BUCKET/workflows/$WORKFLOW_NAME/$WORKFLOW_EXECUTION_ID/$STATE_NAME/translatedConfig.json ${awsdebug} --quiet
    fi
else
    echo "Config file does not exist at: $config_file"
fi

if [ "$RUNTIME_ENV" == "lambda" ]; then
    if [ -n "$1" ]; then
        while IFS="=" read -r key value; do
            export "$key"="$value"
            # echo "Exported: $key=$value"
        done < <(echo "$1" | jq -r 'to_entries[] | "\(.key)=\(.value)"')
    fi
fi

echo "Script completed."

