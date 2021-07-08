#!/usr/bin/env bash

{
    find . -name yarn.lock -o -name package.json
} | grep --invert-match /node_modules/ \
  | grep --invert-match /node/ \
  | xargs dirname \
  | uniq \
  | xargs -I % bash -c "{ pushd %; yarn $*; popd;  }"
