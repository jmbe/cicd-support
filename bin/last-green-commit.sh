#!/bin/bash

# Prefer using pipeline-provided CI_JOB_TOKEN or fall back to GITLAB_PRIVATE_TOKEN
CI_JOB_TOKEN=${CI_JOB_TOKEN:-GITLAB_PRIVATE_TOKEN}

if [[ -z "$CI_JOB_TOKEN" ]]; then
    echo "CI_JOB_TOKEN not provided" >&2
    exit 1
fi

if [[ -z "$CI_PROJECT_ID" ]]; then
    echo "CI_PROJECT_ID not provided" >&2
    exit 2
fi

url="${CI_SERVER_URL:-https://gitlab.com}/api/v4/projects/${CI_PROJECT_ID}/pipelines?private_token=${CI_JOB_TOKEN}&status=success&ref=${CI_COMMIT_REF_NAME}"
#commit=$(curl -s "${url}" | jq -r 'first(.[] | .sha)' 2> /dev/null)
commit=$(curl -s "${url}" | jq -r '.[0].sha' 2>/dev/null)

# Will say "null" when there are no previous green builds
if [[ ! -z "$commit" ]] && [[ "$commit" != "null" ]]; then
    echo "$commit" # Used when capturing output of this command
    echo "$commit" >.LAST_GREEN_COMMIT
else
    echo "Failed to find last green commit" >&2
    which jq >&2
    # curl --silent "${url}"
fi
