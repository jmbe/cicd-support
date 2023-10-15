#!/usr/bin/env bash

# Wrapper which only runs uninstall for existing releases.
# Takes same arguments as helm uninstall, except release-name must be provided first.

releaseName=$1
shift

if [ -z "$releaseName" ]; then
  echo "Release name must be provided"
  exit 1
fi

if helm ls --all --short | grep "^${releaseName}$" >/dev/null; then
  echo "Uninstalling $releaseName..."
  helm uninstall "$releaseName"
else
  echo "Could not find release $releaseName. Skipping uninstall."
  exit 0 # This script is intentionally skipping some projects, so do not fail build
fi
