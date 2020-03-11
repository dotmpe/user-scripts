#!/bin/sh

# A wrapper for builtin stderr logger to be used within user script libs.
# To run as profile or service script libs should depend on $LOG.

logger_std_lib_load()
{
  lib_load logger logger-theme log
}

logger_std_init()
{
  test $# -eq 1 || set -- "$scriptname"

  stderr_log_channel="$1"
  test -z "$verbosity" && {
    stderr_log_level=4
    logger_log_threshold=4
  } || {
    stderr_log_level=$verbosity
    logger_log_threshold=$verbosity
  }
  # XXX exit logger_fd=2 logger_check stderr_demo "Init" 2
}

# ~ MSG [EXIT] [CHANNEL]
emerg() {     test $# -gt 2 || set -- "$@" "" "" ; logger_stderr "1" "$3" "$1" "" "${2-}"; }
crit() {      test $# -gt 2 || set -- "$@" "" "" ; logger_stderr "2" "$3" "$1" "" "${2-}"; }
error() {     test $# -gt 2 || set -- "$@" "" "" ; logger_stderr "3" "$3" "$1" "" "${2-}"; }
warn() {      test $# -gt 2 || set -- "$@" "" "" ; logger_stderr "4" "$3" "$1" "" "${2-}"; }
note() {      test $# -gt 2 || set -- "$@" "" "" ; logger_stderr "5" "$3" "$1" "" "${2-}"; }
std_info() {  test $# -gt 2 || set -- "$@" "" "" ; logger_stderr "6" "$3" "$1" "" "${2-}"; }
debug() {     test $# -gt 2 || set -- "$@" "" "" ; logger_stderr "7" "$3" "$1" "" "${2-}"; }

stderr_demo()
{
  test -n "$1" || set -- "Demo Message"

  local logger_exit_threshold=0
  emerg "$@"
  crit "$@"
  error "$@"
  warn "$@"

  note "$@"
  std_info "$@"
  debug "$@"
}
