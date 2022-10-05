#!/usr/bin/env bash
shopt -s extdebug
set -euETo pipefail

# TODO: clean up other envs and let redo use CI or build or main env?

: "${SUITE:="Main"}"
true "${package_build_tool:="redo"}"
export verbosity="${verbosity:=${v:-3}}"

true "${CWD:="$PWD"}"
true "${PROJECT_CACHE:="$CWD/.meta/cache"}"
true "${COMPONENTS_TXT:="$PROJECT_CACHE/components.list"}"

test -e "${CWD:="$PWD"}/tools/ci/env.sh" && {
  . "$CWD/tools/ci/env.sh" || return
} || {
  . "$U_S/tools/ci/env.sh" || return
}

$LOG "info" "" "Started redo env" "${CWD}/tools/redo/env.sh"
# Id: U-s
