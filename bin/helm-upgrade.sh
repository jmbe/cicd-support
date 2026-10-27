#!/usr/bin/env bash

# Wrapper which only runs upgrade for existing releases.
# Takes same arguments as helm upgrade, except release-name must be provided first.

releaseName=$1
shift

if [ -z "$1" ]; then
  echo "helm upgrade arguments cannot be empty"
  exit 1
fi

# Explicit status flags give the same result on Helm 3 and 4: Helm 3 lists deployed+failed
# by default, while Helm 4 lists all statuses. We want any deployed or failed release, but not
# pending/uninstalled ones, which helm upgrade would reject anyway.
if helm ls --deployed --failed --short | grep "^${releaseName}$" >/dev/null; then
  echo "Upgrading $releaseName..."
  helm upgrade "$releaseName" "$@"
else
  echo "Could not find release $releaseName. Skipping upgrade."
  exit 0 # This script is intentionally skipping some projects, so do not fail build
fi
