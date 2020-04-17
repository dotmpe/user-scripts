#!/usr/bin/env bash

# Boilerplate env for CI scripts

test -z "${ci_env_:-}" && ci_env_=1 || exit 98 # Recursion

set -ueo pipefail
test "${DEBUG-}" = "1" && set -x

: "${SUITE:="CI"}"
: "${CWD:="$PWD"}"
: "${ci_tools:="$CWD/tools/ci"}"
: "${sh_tools:="$CWD/tools/sh"}"
: "${U_S:="$CWD"}" # No-Sync
: "${keep_going:=1}" # No-Sync

. "./tools/sh/parts/debug-exit.sh"

. "./tools/sh/parts/env-0-1-lib-sys.sh"
. "./tools/sh/parts/unique-paths.sh"

ci_env_ts=$($gdate +"%s.%N")
ci_stages="${ci_stages:-} ci_env"

sh_env_ts=$($gdate +"%s.%N")
ci_stages="$ci_stages sh_env"

. "${CWD}/tools/sh/env.sh"

sh_env_end_ts=$($gdate +"%s.%N")

test -n "${ci_util_:-}" || {

  . "$ci_tools/util.sh"
}

test -n "${IS_BASH:-}" || $INIT_LOG error "Not OK" "Need to know shell dist" "" 1

$INIT_LOG note "" "CI Env pre-load time: $(echo "$sh_env_ts - $ci_env_ts"|bc) seconds"
ci_env_end_ts=$($gdate +"%s.%N")

$INIT_LOG note "" "Sh Env load time: $(echo "$ci_env_end_ts - $ci_env_ts"|bc) seconds"
print_yellow "ci:env" "Starting: $0 '$*'" >&2

# From: Script.mpe/0.0.4-dev tools/ci/env.sh
