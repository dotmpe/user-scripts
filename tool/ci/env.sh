#!/usr/bin/env bash

# Boilerplate env for CI scripts

test -z "${ci_env_:-}" && ci_env_=1 || return 96 # Recursion

: "${CWD:="$PWD"}"

test -e "${CWD:="$PWD"}/tools/sh/env.sh" &&
  : "${sh_tools:="$CWD/tools/sh"}" ||
  : "${sh_tools:="$U_S/tools/sh"}"

: "${LOG:="$sh_tools/log.sh"}"

type sh_include >/dev/null 2>/dev/null || {
  . "$U_S/tools/sh/parts/include.sh" || return
}

sh_include env-strict debug-exit \
  env-0-1-lib-sys env-gnu

: "${ci_tools:="$CWD/tools/ci"}"

#shellcheck disable=2154
ci_env_ts=$($gdate +"%s.%N")
ci_stages="${ci_stages:-} ci_env"

: "${SUITE:="CI"}"
: "${U_S:="$CWD"}" # No-Sync
: "${keep_going:=1}" # No-Sync

sh_env_ts=$($gdate +"%s.%N")
ci_stages="$ci_stages sh_env"

test -e "${CWD:="$PWD"}/tools/sh/env.sh" && {
  . "${CWD:="$PWD"}/tools/sh/env.sh" || return
} || {
  . "$U_S/tools/sh/env.sh" || return
}

sh_env_end_ts=$($gdate +"%s.%N")

test -n "${ci_util_:-}" || {

  . "$U_S/tools/ci/util.sh"
}

: "${INIT_LOG:="$CWD/tools/sh/log.sh"}"

$INIT_LOG note "" "CI Env pre-load time: $(echo "$sh_env_ts - $ci_env_ts"|bc) seconds"
ci_env_end_ts=$($gdate +"%s.%N")

$INIT_LOG note "" "Sh Env load time: $(echo "$ci_env_end_ts - $ci_env_ts"|bc) seconds"
test -z "${CI:-}" || {
  test "${verbosity:-${v:-3}}" -lt 4 ||
    print_yellow "ci:env:${SUITE}" "Starting: $0 ${_ENV-} #$#:'$*'" >&2
}
# From: Script.mpe/0.0.4-dev tools/ci/env.sh
