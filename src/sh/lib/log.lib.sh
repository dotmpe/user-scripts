#!/bin/sh

## Log helper module

log_lib__load ()
{
  : "${LOG:=${U_S}/tools/sh/log.sh}"
}

log_lib__init () # ~ [<Name=us>]
{
  test -z "${log_lib_init-}" || return $_
  lib_require stdlog-uc date date-htd || return
  test $# -le 1 || return 193
  test -n "${1:-}" || set -- us

  local lv=${1}_log
  test -n "${!lv-}" || {
    test -n "${LOG-}" || return
    test \( \
        "$(type -t "$LOG")" = "function" -o \
        -x "$LOG" -o -x "$(command -v "$LOG")" \
      \) || return

    #declare -g $lv="$LOG"
    eval $lv="$LOG"
  }
}

req_log ()
{
  test $# -le 1 || return 193
  test -n "${1:-}" || set -- us

  local lv=${1}_log
  test -n "${!lv}" || return 111 # NOTE: sanity
}

req_init_log ()
{
  log_lib__init "$@" && req_log "$@"
}
