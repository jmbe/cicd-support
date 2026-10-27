#!/usr/bin/env bash

# Wrapper which only runs uninstall for existing releases.
# Takes same arguments as helm uninstall, except release-name must be provided first.

# Align Helm 3/4 results so releases of any status are found: Helm 3 needs `--all`
# to include e.g. pending/uninstalled releases, while Helm 4 removed the flag and
# lists all statuses by default.
HELM_LIST_ALL=""
case "$(helm version --template '{{.Version}}')" in
  v3.*) HELM_LIST_ALL="--all" ;;
esac

releaseName=$1
shift

if [ -z "$releaseName" ]; then
  echo "Release name must be provided"
  exit 1
fi

if helm ls $HELM_LIST_ALL --short | grep "^${releaseName}$" >/dev/null; then
  echo "Uninstalling $releaseName..."
  helm uninstall "$releaseName"
else
  echo "Could not find release $releaseName. Skipping uninstall."
  exit 0 # This script is intentionally skipping some projects, so do not fail build
fi
