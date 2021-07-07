#!/usr/bin/env bash

function requireDependency() {
    local jar=$1
    local artifact=$2

    if [ ! -f ${jar} ]; then
        echo "Could not find ${jar}. Downloading..."
        mvn org.apache.maven.plugins:maven-dependency-plugin:3.1.1:get -Dtransitive=false -Dartifact=${artifact}
    fi

}
