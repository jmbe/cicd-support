#!/usr/bin/env bash

# Updates node_modules for packages changed since last push.

if [ ! -d .git ]; then
    echo "Must be run from git repository root directory" >&2
    exit 2
fi

# https://www.atlassian.com/git/tutorials/git-forks-and-upstreams
curr_branch=$(git rev-parse --abbrev-ref HEAD)
curr_remote=$(git config branch.$curr_branch.remote)
curr_merge_branch=$(git config branch.$curr_branch.merge | cut -d / -f 3)
upstream_ref=$curr_remote/$curr_merge_branch

{
    git diff --name-only -z "$upstream_ref"
    git ls-files --others --exclude-standard
} | grep --null-data --null "package.json$" | xargs --null dirname | sort --unique | xargs -I % bash -c '{ pushd %; yarn; popd; }'
