#!/bin/sh

## Log helper module

log_lib_load ()
{
  test -n "${LOG-}" || LOG=${U_S}/tools/sh/log.sh
}

log_lib_init ()
{
  test -n "${us_log-}" || {
    test -n "${LOG-}" || return
    test \( \
        "$(type -t "$LOG")" = "function" -o \
        -x "$(which "$LOG")" -o -x "$LOG" \
      \) || return
    us_log="$LOG"
  }
}

req_log ()
{
  test -n "$us_log" || exit 111 # NOTE: sanity
}

req_init_log ()
{
  log_lib_init && req_log
}
