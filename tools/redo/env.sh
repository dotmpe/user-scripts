#!/usr/bin/env bash
shopt -s extdebug
set -euETo pipefail

# TODO: clean up other envs and let redo use CI or build or main env?

: "${SUITE:="Main"}"
true "${package_build_tool:="redo"}"
true "${init_sh_libs:="os sys str match log shell script $package_build_tool build"}"
true "${build_parts_bases:="$(for base in ${!package_tools_redo_parts_bases__*}; do eval "echo ${!base}"; done )"}"
true "${build_parts_bases:="$UCONF/tools/redo/parts $HOME/bin/tools/redo/parts $U_S/tools/redo/parts"}"
true "${build_main_targets:="${package_tools_redo_targets_main-"all help build test"}"}"
true "${build_all_targets:="${package_tools_redo_targets_all-"build test"}"}"
true "${DEBUG:=${REDO_DEBUG-${DEBUG-}}}"
export verbosity="${verbosity:=${v:-3}}"
export quiet="${quiet:=${q:-0}}"

true "${CWD:="$PWD"}"
true "${PROJECT_CACHE:="$CWD/.meta/cache"}"
true "${COMPONENTS_TXT:="$PROJECT_CACHE/components.list"}"

true "${redo_opts:="-j4"}"

test -e "${CWD:="$PWD"}/tools/ci/env.sh" && {
  . "$CWD/tools/ci/env.sh" || return
} || {
  . "$U_S/tools/ci/env.sh" || return
}

$LOG "info" "" "Started redo env" "${CWD}/tools/redo/env.sh"
# Id: U-s
