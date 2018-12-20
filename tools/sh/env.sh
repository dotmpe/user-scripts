#!/bin/ash

: "${CWD:=$PWD}"

: "${script_env_init:=$CWD/tools/sh/parts/env.sh}"
. "$script_env_init"

: "${USER_ENV:=tools/sh/env.sh}"
export USER_ENV


: "${LOG:=$CWD/tools/sh/log.sh}"
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



test -z "$LOG" || {
  test -x "$LOG" || {
    test "$LOG" = "logger_stderr" || exit 102

    $CWD/tools/sh/log.sh info "sh:env" "Reloaded existing logger env"
    . $script_util/init.sh
  }
}
