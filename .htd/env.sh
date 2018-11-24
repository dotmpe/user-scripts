#!/usr/bin/env bash

set -o pipefail
#set -e XXX: should be same as
set -o errexit

export uname=${uname:-$(uname -s)}
export LOG=${LOG:-logger_log}
test -n "$SRC_PREFIX" || SRC_PREFIX=/src
test -n "$VND_SRC_PREFIX" || VND_SRC_PREFIX="$SRC_PREFIX"
test -n "$VND_GH_SRC" || VND_GH_SRC="$VND_SRC_PREFIX/github.com"
test -n "$BATS_VERSION" || BATS_VERSION=master
test -n "$BATS_REPO" || BATS_REPO=https://github.com/bats-core/bats-core.git

case "$uname" in
  Darwin )  export gdate=gdate gsed=gsed ggrep=ggrep ;;
  Linux )   export gdate=date gsed=sed ggrep=grep ;;
esac

black="$(tput setaf 0)"
green="$(tput setaf 2)"
yellow="$(tput setaf 3)"
#blue="$(tput setaf 4)"
#purple="$(tput setaf 5)" # magenta
bold="$(tput bold)"
default="$(tput setaf 7)"
print_yellow()
{
  printf "%s[%s%s%s] %s%s%s\n" "$yellow" "$default" "$1" "$yellow" "$default" "$2" "$normal"
}
print_green()
{
  printf "%s[%s%s%s] %s%s%s\n" "$green" "$default" "$1" "$green" "$default" "$2" "$normal"
}

case "$PATH" in
  *"$HOME/.basher/"* ) ;;
  * ) export PATH=$HOME/.basher/bin:$HOME/.basher/cellar/bin:$PATH ;;
esac
