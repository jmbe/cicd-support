#! /usr/bin/env bash

# Modifies the git ref to be suitable for use as a maven version classifier (sha1 field).
# This is supposed to match https://gitlab.com/intem-oss/maven-config-branchtool/-/blob/master/roles/maven-config-git-flow-hooks/files/post-flow-feature-start
# for feature branches, while also using an empty sha1 for common trunk branch names.

FEATURE_SHA1=$(git rev-parse --abbrev-ref HEAD | sed 's#feature/##' | sed 's#[-/]#_#g' | sed --regexp-extended 's#^(develop|master|main)$##')

echo $FEATURE_SHA1
