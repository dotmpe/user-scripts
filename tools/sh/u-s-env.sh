#!/usr/bin/env bash

U_S_REPO_ID="origin"
U_S_REPO="dotmpe/user-scripts"
# FIXME ssh setup U_S_REPO_URL="git@github.com:"
U_S_REPO_URL="https://github.com/$U_S_REPO"
U_S_RELEASE="r0.0"

test -z "${INIT_DEBUG:=}" || set +x

# Look at host / env and export u-s install type

# TODO: cleanup some dynamic parts to bin/u-s env
#if usr
#elif usr-local

#elif dev|basher
#test -n "$U_S" || U_S="$(basher package-path ...)"

#else dev-local
#test -n "$U_S" || U_S="$(pwd -P)"

: "${CWD:="$PWD"}"
: "${ci_tools:="$CWD/tools/ci"}"
. "$CWD/tools/sh/parts/unique-paths.sh" || return
. "$CWD/tools/sh/parts/env-scriptpath-deps.sh" || return
. "$ci_tools/env.sh" || return

{ test -x "$(which basher 2>/dev/null)" &&
  test "$(basher package-path "$U_S_REPO")" = "$U_S"
} && U_S_TYPE=basher

: "${U_S_TYPE:="dev"}"

u_s_env_init()
{
  case "$U_S_TYPE" in

    dev )
      ;;

    basher ) #basher package-path $U_S_REPO
      ;;

    * ) $LOG "error" "" "No such U-s install type" "$U_S_TYPE" 1 ;;
  esac
}

test -z "$INIT_DEBUG" || set +x

# XXX: unset INIT_LOG
U_S_ENV=dev

test -z "$DEBUG" || set -x
