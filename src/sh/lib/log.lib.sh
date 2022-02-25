#!/bin/sh

## Log helper module

log_lib_load ()
{
  test -n "${LOG-}" || LOG=${U_S}/tools/sh/log.sh
}

log_lib_init () # ~ [<Name=us>]
{
  test $# -le 1 || return 177
  test -n "${1:-}" || set -- us

  local lv=${1}_log
  test -n "${!lv-}" || {
    test -n "${LOG-}" || return
    test \( \
        "$(type -t "$LOG")" = "function" -o \
        -x "$LOG" -o -x "$(which "$LOG")" \
      \) || return

    #declare -g $lv="$LOG"
    eval $lv="$LOG"
  }
}

req_log ()
{
  test $# -le 1 || return 177
  test -n "${1:-}" || set -- us

  local lv=${1}_log
  test -n "${!lv}" || return 111 # NOTE: sanity
}

req_init_log ()
{
  log_lib_init "$@" && req_log "$@"
}
