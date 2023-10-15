#!/usr/bin/env bash

# Wrapper which only runs upgrade for existing releases.
# Takes same arguments as helm upgrade, except release-name must be provided first.

releaseName=$1
shift

if [ -z "$1" ]; then
  echo "helm upgrade arguments cannot be empty"
  exit 1
fi

if helm ls --all --short | grep "^${releaseName}$" >/dev/null; then
  echo "Upgrading $releaseName..."
  helm upgrade "$releaseName" "$@"
else
  echo "Could not find release $releaseName. Skipping upgrade."
  exit 0 # This script is intentionally skipping some projects, so do not fail build
fi
