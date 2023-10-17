#!/bin/bash

TASK_DEFINITION_FILE=".github/aws/task-definition.json"
SEMVER=""

# get parameters
while getopts v flag
do
  case "$flag" in
    v) SEMVER=${OPTARG};;
    *) echo "usage: $0 [-v]" >&2
        exit 1;;
  esac
done

# Make sure that the task definition file exists
if [ -f "$TASK_DEFINITION_FILE" ]; then
    jq --arg newVersion "$SEMVER" '.containerDefinitions[0].image |= (sub(":latest$"; ":" + $newVersion))' "$TASK_DEFINITION_FILE" > tmp.json

    jq_exit_code=$?

    # check if jq command is successfully then update the file
    if [ "$jq_exit_code" -eq 0 ]; then
        mv tmp.json "$TASK_DEFINITION_FILE"
        echo "Set TAG to $SEMVER"
    else
        echo "Failed to update the image tag."
    fi
else
    echo "Failed to set the tag."
fi

exit 0
