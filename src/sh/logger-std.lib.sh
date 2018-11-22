#!/bin/sh

logger_std_lib_load()
{
  lib_load logger
}

emerg() { logger_stderr "emerg" "" "$1" "" "$2"; }
crit() { logger_stderr "crit" "" "$1" "" "$2"; }
error() { logger_stderr "error" "" "$1" "" "$2"; }
warn() { logger_stderr "warn" "" "$1" "" "$2"; }
note() { logger_stderr "note" "" "$1" "" "$2"; }
info() { logger_stderr "info" "" "$1" "" "$2"; }
debug() { logger_stderr "debug" "" "$1" "" "$2"; }

stderr_demo()
{
  emerg "Demo Message"
  crit "Demo Message"
  error "Demo Message"
  warn "Demo Message"
  note "Demo Message"
  info "Demo Message"
  debug "Demo Message"
}
