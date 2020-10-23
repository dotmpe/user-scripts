#!/usr/bin/env bash

# Shell env profile script

test -z "${sh_env_:-}" && sh_env_=1 || return 98 # Recursion

test ${DEBUG:-0} -ne 0 || DEBUG=
: "${CWD:="$PWD"}"
: "${sh_tools:="$CWD/tools/sh"}"

test "${env_strict_-}" = "0" || {
  . "$sh_tools/parts/env-strict.sh" && env_strict_=$?; }

# FIXME: generate local static env
true "${BIN:="$HOME/bin"}"
test ! -e $BIN/.env.sh || . $BIN/.env.sh
test ! -e $CWD/.htd/meta.sh || . $CWD/.htd/meta.sh

: "${SUITE:="Sh"}"
: "${APP_LBL:="User-Scripts"}" # No-Sync
: "${APP_ID:="user_scripts"}" # No-Sync
: "${APP_LBL_BREV:="U-S"}" # No-Sync
: "${APP_ID_BREV:="u_s"}" # No-Sync
: "${sh_main_cmdl:="spec"}"
: "${U_S_MAN:="$U_S/src/md/manuals.list"}"
export scriptname=${scriptname:-"`basename -- "$0"`"}

test -n "${sh_util_:-}" || {

  . "$sh_tools/util.sh"
}

: "${LOG:="print_err"}"

sh_include \
  print-color remove-dupes unique-paths \
  env-0-src

: "${build_txt:="build.txt"}"

test -z "${DEBUG:-}" -a -z "${CI:-}" ||
  print_yellow "${SUITE} Env parts" "$(suite_from_table "${build_txt}" "Parts" "${SUITE}" 0|tr '\n' ' ')" >&2

suite_source "${build_txt}" "${SUITE}" 0

test -z "${DEBUG:-}" || print_green "" "Finished sh:env ${SUITE} <$0>"

# Id: user-script/ tools/sh/env.sh
