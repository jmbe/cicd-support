#! /usr/bin/env bash

function replace_version() {

    previous=develop-$(date --date='-1 month' +%y.%m)
    next=develop-$(date +%y.%m)

    if [ -z "$1" ]; then
        echo "Must provide path"
        return 1
    fi



    grep "$previous" $1 -Rl | while IFS= read -r f
    do
    echo "Replacing version in $f..."
    sed --in-place s/"$previous"/"$next"/ "$f"
    done

}


function bump_chart() {
    chart="$1/Chart.yaml"
    if [ ! -f "$chart" ]; then
        echo "Could not find Chart.yaml in $1"
        exit 1
    fi

    next=$(date +%y.%-m.0)

    echo "Bumping version in $chart..."
    sed --in-place s/version:.*/"version: $next"/ "$chart"

}

if [ -z "$1" ]; then
    echo "Usage:"
    echo "    $(basename $0) DIRECTORY                 Where DIRECTORY contains Chart.yaml"
    exit 1
else
    bump_chart "$1"
    replace_version "$1"

    pushd $1
    git status
    popd
fi
