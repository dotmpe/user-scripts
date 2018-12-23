#!/bin/sh

log_lib_init()
{
  test -n "$LOG" && init_log="$LOG" || init_log="$INIT_LOG"
}


req_log()
{
  test -n "$log" || exit 102 # NOTE: sanity
}

req_init_log() { test -n "$LOG"&&log="$LOG"||log="$init_log";req_log; }
