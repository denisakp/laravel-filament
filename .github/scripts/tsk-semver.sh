#!/bin/bash

TASK_DEFINITION_FILE=".github/aws/task-definition.json"
SEMVER=""

# get parameters
while getopts v: flag
do
  case "${flag}" in
    v) SEMVER=${OPTARG};;
  esac
done

# Make sure that the task defintion file exists 
if [ -f "$TASK_DEFINITION_FILE" ]; then
    jq --arg newVersion "$SEMVER" '.containerDefinitions[0].image |= (sub(":latest$"; ":" + $newVersion))' "$TASK_DEFINITION_FILE" > tmp.json

    # check if jq command is successfull then update the file
    if [ $? -eq 0 ]; then
        mv tmp.json "$TASK_DEFINITION_FILE"
        echo "Set TAG to $SEMVER"
    else
        echo "Failed to update the image tag."
    fi
else
    echo "Failed to set the tag."
fi

exit 0
