#!/bin/ash
# XXX: usr/bin/env bash

# NOTE: set default bash-profile (affects other Shell scripts)
#: "${BASH_ENV:=$0}"
#export BASH_ENV

: "${LOG:=$PWD/tools/sh/log.sh}"
: "${CS:=dark}"
export LOG CS

: "${SRC_PREFIX:=/src}"
: "${VND_SRC_PREFIX:=$SRC_PREFIX}"
: "${VND_GH_SRC:=$VND_SRC_PREFIX/github.com}"
: "${BATS_VERSION:=v1.1.0}"
: "${BATS_REPO:=https://github.com/bats-core/bats-core.git}"
export SRC_PREFIX VND_SRC_PREFIX VND_GH_SRC

export scriptname=${scriptname:-$(basename "$0")}

export uname=${uname:-$(uname -s)}

test -n "${GITHUB_TOKEN:-}" || {
  . ~/.local/etc/profile.d/github-user-scripts.sh || exit 101
}

case "$PATH" in
  *"$HOME/.basher/"* ) ;;
  * ) export PATH=$HOME/.basher/bin:$HOME/.basher/cellar/bin:$PATH ;;
esac
