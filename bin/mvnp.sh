#!/usr/bin/env bash

# Runs maven for modules changed in last pull
# e.g. mvnp.sh package

WORKSPACE_ROOT=$(readlink -f $(dirname "$0")/../..)
# shellcheck disable=SC1090
source "$WORKSPACE_ROOT"/.cicd/bin/affected-modules.sh 2>/dev/null

changedfiles=$({
    git diff HEAD@{1} --name-only -z
} | grep --null-data --null --extended-regexp --invert-match "^\.(idea|development|cicd|editorconfig|mvn)|\.(iml)$" | xargs --null dirname | sort --unique | findpom | sort --unique)

modules=""
if [[ -n "$changedfiles" ]]; then
    # shellcheck disable=SC2086
    modules=$(echo ${changedfiles} | xargs --null echo | to_array)
fi

if [[ -n "$modules" ]]; then
    "$WORKSPACE_ROOT"/mvnw --projects "$modules" "$@"
else
    echo "No changes detected" >&2
fi
