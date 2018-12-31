#!/bin/ash

# Look at host / env and export u-s install type

# TODO: some dynamic parts to bin/u-s env
#if usr
#elif usr-local

#elif dev|basher
#test -n "$U_S" || U_S="$(basher package-path ...)"

test -n "${U_S:-}" || U_S="$(dirname "$(dirname "$(realpath "$0")")")"

#else dev-local
#test -n "$U_S" || U_S="$(pwd -P)"

: "${script_util:="$U_S/tools/sh"}"
. "${script_util}/util.sh"
. "${script_util}/parts/print-color.sh"
. "${script_util}/parts/env-0.sh"
. "${script_util}/parts/env-dev.sh"

set +o nounset # NOTE: apply nounset only during init

U_S_ENV=dev
export U_S_ENV U_S
