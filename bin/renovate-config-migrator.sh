#!/usr/bin/env bash

# If there are config changes, the json will be prefixed with a couple of spaces
output=$(npx --yes --package renovate@latest -- renovate-config-validator | grep "^    ")

if [ -n "$output" ]; then
  # Wrap output with {} (missing in log output) and separate old and new config
  echo "{$output}" | jq .newConfig > newConfig.tmp.json5
  echo "{$output}" | jq .oldConfig > oldConfig.tmp.json5

  meld oldConfig.tmp.json5 newConfig.tmp.json5
else
  echo
  echo "*** Migration appears complete"
fi
