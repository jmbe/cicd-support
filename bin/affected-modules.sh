#! /usr/bin/env bash

revision=${1:-$CI_COMMIT_BEFORE_SHA}

echo "Checking changes from revision ${revision} forwards..." >&2

function upsearch() {

  local x=$1;
#  echo "Initial: $x"

  while [ "$x" != "/" ] ;  do
    #echo "Looking in $x"
    if [ -e "$x/$2" ]; then
       echo "$x"
       break;
    fi

    x=$(dirname "$x");

  done
}

# http://zaiste.net/2015/05/how_to_join_elements_of_an_array_in_bash/
function join_s { local IFS="$1"; shift; echo "$*"; }

function findpom() {
  paths=()

  while read -r line; do
    # Collect paths piped to script
    #echo "Read path $line" >&2
    project=$(upsearch ${line} "pom.xml")
    printf '%s\n' ${project}
  done

}

function to_array() {
  lines=()

  while read -r line; do
    lines+=(${line})
  done

  list=$(join_s "," "${lines[@]}")
  echo ${list}
}


if [[ ! -z "$revision" ]] && [[ "$revision" != "0000000000000000000000000000000000000000" ]]; then
  modules=$(git diff --name-only ..${revision} | xargs --max-args=1 dirname | sort --unique | findpom | sort --unique | to_array)
  echo "--also-make-dependents --projects ${modules}"
fi
