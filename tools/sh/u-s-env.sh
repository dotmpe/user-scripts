#!/usr/bin/env bash

U_S_REPO_ID="origin"
U_S_REPO="bvberkum/user-scripts"
# FIXME ssh setup U_S_REPO_URL="git@github.com:"
U_S_REPO_URL="https://github.com/$U_S_REPO"
U_S_RELEASE="r0.0"

test -z "${INIT_DEBUG:=}" || set +x

# Look at host / env and export u-s install type

: "${U_S:="$(dirname "$(dirname "$(realpath "$0")")")"}"

# TODO: cleanup some dynamic parts to bin/u-s env
#if usr
#elif usr-local

#elif dev|basher
#test -n "$U_S" || U_S="$(basher package-path ...)"

#else dev-local
#test -n "$U_S" || U_S="$(pwd -P)"

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

: "${CWD:="$PWD"}"
: "${script_util:="$U_S/tools/sh"}"
. "${script_util}/util.sh"
. "${script_util}/parts/print-color.sh"
. "${script_util}/parts/env-0.sh"
. "${script_util}/parts/env-dev.sh"

test -z "$INIT_DEBUG" || set +x
set +o nounset # NOTE: apply nounset only during init

unset INIT_LOG
U_S_ENV=dev
export U_S_ENV U_S

test -z "$DEBUG" || set -x
