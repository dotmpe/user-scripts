#!/usr/bin/env bash

# Boilerplate env for CI scripts

test -z "${ci_env_:-}" && ci_env_=1 || exit 98 # Recursion

: "${CWD:="$PWD"}"
: "${sh_tools:="$CWD/tools/sh"}"
: "${LOG:="$sh_tools/log.sh"}"

sh_include env-strict debug-exit \
  env-0-1-lib-sys env-gnu

: "${ci_tools:="$CWD/tools/ci"}"

ci_env_ts=$($gdate +"%s.%N")
ci_stages="${ci_stages:-} ci_env"

: "${SUITE:="CI"}"
: "${U_S:="$CWD"}" # No-Sync
: "${keep_going:=1}" # No-Sync

sh_env_ts=$($gdate +"%s.%N")
ci_stages="$ci_stages sh_env"

. "${CWD}/tools/sh/env.sh"

sh_env_end_ts=$($gdate +"%s.%N")

test -n "${ci_util_:-}" || {

  . "$ci_tools/util.sh"
}

: ${INIT_LOG:="$CWD/tools/sh/log.sh"}

$INIT_LOG note "" "CI Env pre-load time: $(echo "$sh_env_ts - $ci_env_ts"|bc) seconds"
ci_env_end_ts=$($gdate +"%s.%N")

$INIT_LOG note "" "Sh Env load time: $(echo "$ci_env_end_ts - $ci_env_ts"|bc) seconds"
test -z "${CI:-}" || {
  test ${verbosity:-${v:-3}} -lt 4 ||
    print_yellow "ci:env:${SUITE}" "Starting: $0 ${_ENV-} #$#:'$*'" >&2
}
# From: Script.mpe/0.0.4-dev tools/ci/env.sh
