#!/usr/bin/env bash

# Shell env profile script

test -z "${sh_env_:-}" && sh_env_=1 || return 98 # Recursion

: "${CWD:="$PWD"}"
: "${sh_tools:="$CWD/tools/sh"}"
: "${U_S:="$CWD"}"

. "$U_S/tools/sh/parts/env-strict.sh"

: "${ci_tools:="$CWD/tools/ci"}"
: "${build_tab:="build.txt"}"

: "${APP_ID:="user-scripts"}" # No-Sync
: "${SUITE:="Sh"}"
: "${sh_main_cmdl:="spec"}"
export scriptname=${scriptname:-"`basename -- "$0"`"}

test -n "${sh_util_:-}" || {

  . "$sh_tools/util.sh"
}

sh_include \
  env-0-1-lib-sys \
  print-color remove-dupes unique-paths \
  env-0-src
SCRIPTPATH=

test -z "${DEBUG:-}" -a -z "${CI:-}" ||
  print_yellow "${SUITE} Env parts" "$(suite_from_table "${build_tab}" "Parts" "${SUITE}" 0|tr '\n' ' ')" >&2

suite_source "${build_tab}" "${SUITE}" 0

test -z "${DEBUG:-}" || print_green "" "Finished sh:env ${SUITE} <$0>"

# Id: user-script/ tools/sh/env.sh
