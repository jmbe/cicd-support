#! /usr/bin/env bash

# Modifies the git ref to be suitable for use as a maven version classifier (sha1 field).
# This is supposed to match https://gitlab.com/intem-oss/maven-config-branchtool/-/blob/master/roles/maven-config-git-flow-hooks/files/post-flow-feature-start
# for feature branches, while also using an empty sha1 for common trunk branch names.

# The script assumes this will be run on GitLab where CI_COMMIT_REF_NAME is available. Note that GitLab will use
# a detached head, so git rev-parse will not work to find branch name (https://gitlab.com/gitlab-org/gitlab/-/issues/15409).

FEATURE_SHA1=$(echo $CI_COMMIT_REF_NAME | sed 's#feature/##' | sed 's#[-/]#_#g' | sed --regexp-extended 's#^(develop|master|main)$##')

echo $FEATURE_SHA1
