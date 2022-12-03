#! /usr/bin/env bash

length=${1:-16}

# https://unix.stackexchange.com/a/419855/378722
function bcryptPassword() {
    local rawPassword=$1
    local hashed=$(htpasswd -bnBC 10 "" $rawPassword | tr -d ':\n' | sed 's/$2y/{bcrypt}$2a/')
    echo $hashed
}

function displayHashed() {
    local plain=$1
    local hashed=$(bcryptPassword $plain)
    echo "$plain"
    echo "$hashed"
}

echo "Mixed:"
plain=$(tr -dc _A-Z-a-z-0-9 </dev/urandom | head -c${length})
displayHashed $plain
echo ""

# Lower-case only
echo
echo "Lower-case only:"
plain=$(tr -dc a-z0-9 </dev/urandom | head -c${length})
displayHashed $plain
echo ""

# Readable only
echo
echo "Readable only:"
plain=$(tr -dc 23456789abcdefghjkmnpqrstuwxz </dev/urandom | head -c${length})
displayHashed $plain
