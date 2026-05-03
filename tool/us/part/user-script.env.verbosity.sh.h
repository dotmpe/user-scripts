# Copyright 2008-2026 B. van Berkum <dev@dotmpe.com>
#
# Distributed under terms of the MIT license.
#ifndef USER_SCRIPT_ENV_BASH
#define USER_SCRIPT_ENV_BASH
#if LANG == bash
: "${DEBUG:=0}"
QUIET_update ()
{
  if [[ ! ${VERBOSE:+set} ]]
  then
    : "${QUIET:=0}"
    ((QUIET)) && VERBOSE=0 || : "${VERBOSE:=0}"
  else
    ((VERBOSE)) && QUIET=0 || QUIET=1
  fi
}
QUIET_update
#else
#error unsupported shell LANG
#endif
#endif
#
# Id: user-script.env.verbosity.sh.h             vim:set ft=bash sw=2 sts=2 et:
