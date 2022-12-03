#! /usr/bin/env bash

if [ -z "$2" ]; then
    echo "Usage: $(basename $0) package command-to-execute..."
    echo
    echo "Examples:"
    echo
    echo "  $(basename $0) @angular/cli ng update @angular/cli --allow-dirty"
    # Note that package @angular/cli is intended in the next sample, to support running ng
    echo "  $(basename $0) @angular/cli \"yarn && ng update @angular/core --allow-dirty --force\""
    # Sample for major Angular upgrades, e.g. 9 -> 10
    echo "  $(basename $0) @angular/cli \"yarn && ng update @angular/core @angular/cli --allow-dirty --force\""
    echo "  $(basename $0) @ngxs-labs/data yarn add @ngxs-labs/data@3.0.5"
    # Take care to quote properly when the command line to run uses pipes
    echo "  $(basename $0) @angular-devkit/build-angular \"cat package.json | jq '.resolutions.typescript = \\\"3.8.3\\\"' | sponge package.json && yarn\""
    # Sample selective resolution, keyname must be quoted
    echo "  $(basename $0) @angular-devkit/build-angular \"cat package.json | jq '.resolutions.\\\"@angular-devkit/**/typescript\\\" = \\\"3.8.3\\\"' | sponge package.json && yarn\""
    echo "  $(basename $0) tslint \"pwd && yarn && yarn run tslint --fix\""
    echo
    exit 1
fi

package=$1
shift
cmd=$*

echo $package
echo $cmd

{
    ack --type-set pj:match:package\.json --pj $package --files-with-matches
} | xargs dirname | xargs -I % bash -c "{ pushd %; $cmd; popd; }"
