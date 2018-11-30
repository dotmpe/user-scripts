#!/bin/sh

# A wrapper for builtin stderr logger to be used within user script libs.
# To run as profile or service script libs should depend on $LOG.

logger_std_lib_load()
{
  lib_load logger logger-theme
}

logger_std_init()
{
  test -n "$1" || set -- "$scriptname"

  stderr_log_channel="$1"
  stderr_log_level=$verbosity
  logger_log_threshold=$verbosity
  logger_fd=2 logger_check stderr_demo "Init" 2
}

# ~ MSG [EXIT] [CHANNEL]
emerg() { logger_stderr "1" "$3" "$1" "" "$2"; }
crit() {  logger_stderr "2" "$3" "$1" "" "$2"; }
error() { logger_stderr "3" "$3" "$1" "" "$2"; }
warn() {  logger_stderr "4" "$3" "$1" "" "$2"; }
note() {  logger_stderr "5" "$3" "$1" "" "$2"; }
info() {  logger_stderr "6" "$3" "$1" "" "$2"; }
debug() { logger_stderr "7" "$3" "$1" "" "$2"; }

stderr_demo()
{
  test -n "$1" || set -- "Demo Message"
  emerg "$@"
  crit "$@"
  error "$@"
  warn "$@"
  note "$@"
  info "$@"
  debug "$@"
}
