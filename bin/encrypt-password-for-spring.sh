#! /usr/bin/env bash

# https://unix.stackexchange.com/a/419855/378722
function bcryptPassword() {
    local rawPassword=$1
    local hashed=$(htpasswd -bnBC 10 "" $rawPassword | tr -d ':\n' | sed 's/$2y/{bcrypt}$2a/')
    echo $hashed
}

function showEncryptedPassword() {
    local plain=$1
    local hashed=$(bcryptPassword $plain)
    echo "Password for use with Spring Security:"
    echo "$hashed"
}

read -s -p "Entered password to encrypt: " password

if [ ! -z "$password" ]; then
    echo
    echo
    showEncryptedPassword "$password"
fi
