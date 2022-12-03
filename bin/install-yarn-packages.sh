#!/usr/bin/env bash

# Delegate to deno implementation if deno can be found
if [ -x "$(command -v deno)" ]; then
    # This indirection is required for Ubuntu 18.04. With newer versions the ts file can be called directly
    deno run --allow-read --allow-run $(dirname $0)/install-yarn-packages.ts
    exit $?
fi

# Fall back to legacy script implementation if deno cannot be found
{
    find . -not \( -path "*/node_modules/*" -prune -o -path "*/node/*" -prune \) -a \( -name yarn.lock -o -name package.json \)
} | grep --invert-match /node_modules/ \
  | grep --invert-match /node/ \
  | xargs dirname \
  | uniq \
  | xargs -I % bash -c "{ pushd %; yarn $*; popd;  }"
