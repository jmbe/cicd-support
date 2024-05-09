#!/bin/bash

# When testing locally, provide a personal access token with scope api
# https://gitlab.com/-/user_settings/personal_access_tokens
#
# Note that the pipeline-provided CI_JOB_TOKEN is not able to access the required API in GitLab 17.0 and
# gives 401 errors. A separate token must be configured in CI/CD environment variables for the group or project.
# https://docs.gitlab.com/ee/ci/jobs/ci_job_token.html
if [[ -z "$GITLAB_PRIVATE_TOKEN" ]]; then
    echo "GITLAB_PRIVATE_TOKEN not provided" >&2
    exit 1
fi

if [[ -z "$CI_PROJECT_ID" ]]; then
    echo "CI_PROJECT_ID not provided" >&2
    exit 2
fi

url="${CI_SERVER_URL:-https://gitlab.com}/api/v4/projects/${CI_PROJECT_ID}/pipelines?status=success&ref=${CI_COMMIT_REF_NAME}"
#commit=$(curl -s "${url}" | jq -r 'first(.[] | .sha)' 2> /dev/null)
commit=$(curl --header "PRIVATE-TOKEN: ${GITLAB_PRIVATE_TOKEN}" -s "${url}" | jq -r '.[0].sha' 2>/dev/null)

# Will say "null" when there are no previous green builds
if [[ ! -z "$commit" ]] && [[ "$commit" != "null" ]]; then
    echo "$commit" # Used when capturing output of this command
    echo "$commit" >.LAST_GREEN_COMMIT
else
    echo "Failed to find last green commit" >&2
    which jq >&2
    # curl --silent "${url}"
fi
