#!/usr/bin/env bash

#set -o nounset
set -o pipefail
#set -e XXX: should be same as
set -o errexit

export uname=${uname:-$(uname -s)}
#export LOG=${LOG:-logger_log}
export LOG=${LOG:-./tools/sh/log.sh}


test -n "${GITHUB_TOKEN:-}" || {
  . ~/.local/etc/profile.d/github-user-scripts.sh || exit $?
}


: "${SRC_PREFIX:=/src}"
: "${VND_SRC_PREFIX:=$SRC_PREFIX}"
: "${VND_GH_SRC:=$VND_SRC_PREFIX/github.com}"
: "${BATS_VERSION:=v1.1.0}"
: "${BATS_REPO:=https://github.com/bats-core/bats-core.git}"

# XXX: shouldnt use this in bash
fnmatch() { case "$2" in $1 ) return;; * ) return 1;; esac; }

case "$uname" in
  Darwin )  export gdate=gdate gsed=gsed ggrep=ggrep ;;
  Linux )   export gdate=date gsed=sed ggrep=grep ;;
esac

c_normal="$(tput sgr0)"
c_black="$(tput setaf 0)"
c_red="$(tput setaf 1)"
c_green="$(tput setaf 2)"
c_yellow="$(tput setaf 3)"
#c_blue="$(tput setaf 4)"
#c_purple="$(tput setaf 5)" # magenta
c_bold="$(tput bold)"
c_default="$(tput setaf 7)"
print_red()
{
  test -n "$1" || set -- "$scriptname" "$2"
  printf "%s[%s%s%s] %s%s%s\n" "$c_red" "$c_default" "$1" "$c_red" "$c_default" "$2" "$c_normal"
}
print_yellow()
{
  test -n "$1" || set -- "$scriptname" "$2"
  printf "%s[%s%s%s] %s%s%s\n" "$c_yellow" "$c_default" "$1" "$c_yellow" "$c_default" "$2" "$c_normal"
}
print_green()
{
  test -n "$1" || set -- "$scriptname" "$2"
  printf "%s[%s%s%s] %s%s%s\n" "$c_green" "$c_default" "$1" "$c_green" "$c_default" "$2" "$c_normal"
}

case "$PATH" in
  *"$HOME/.basher/"* ) ;;
  * ) export PATH=$HOME/.basher/bin:$HOME/.basher/cellar/bin:$PATH ;;
esac
