#!/usr/bin/env bash

# Runs maven for affected modules only, modules changed since last push
# e.g. mvna.sh test

WORKSPACE_ROOT=$(readlink -f $(dirname "$0")/../..)
# shellcheck disable=SC1090
source "$WORKSPACE_ROOT"/.cicd/bin/affected-modules.sh 2>/dev/null

# https://www.atlassian.com/git/tutorials/git-forks-and-upstreams
curr_branch=$(git rev-parse --abbrev-ref HEAD)
curr_remote=$(git config branch.$curr_branch.remote)
curr_merge_branch=$(git config branch.$curr_branch.merge | cut -d / -f 3-)
upstream_ref=$curr_remote/$curr_merge_branch

changedfiles=$({
    git diff --name-only -z "$upstream_ref"
    git ls-files --others --exclude-standard
} | grep --null-data --null --extended-regexp --invert-match "^\.(idea|development|cicd|editorconfig|mvn)|\.(iml)$" | xargs --null dirname | sort --unique | findpom | sort --unique)

modules=""
if [[ -n "$changedfiles" ]]; then
    # shellcheck disable=SC2086
    modules=$(echo ${changedfiles} | xargs --null echo | to_array)
fi

if [[ -n "$modules" ]]; then
    mvn="$WORKSPACE_ROOT"/mvnw

    if command -v mvnd > /dev/null; then
        mvn="mvnd --threads=0.3C"
    fi

    $mvn --also-make-dependents --projects "$modules" "$@"
else
    echo "No changes detected" >&2
fi
