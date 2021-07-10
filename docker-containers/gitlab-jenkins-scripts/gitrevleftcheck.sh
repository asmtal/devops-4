#!/usr/bin/env bash

function checkBehindMaster(){
printf "current branch is $1\n"
left=$(git rev-list --left-only --count origin/master...origin/$1)
printf "$1 is $left commits behind master\n"
if [[ "$left" -ne 0 ]]; then
    printf "You must rebase your branch to master!!!\n";
    exit 1
fi
exit 0
}

checkBehindMaster "$@"