# Copyright 2008-2026 B. van Berkum <dev@dotmpe.com>
#
# Distributed under terms of the MIT license.
#ifndef USER_SCRIPT_ENV_STANDARD_BASH
#define USER_SCRIPT_ENV_STANDARD_BASH
#if LANG == bash
: "${ASSERT:=0}"
: "${DEV:=0}"
: "${DIAG:=0}"
: "${INIT:=0}"
! { ((DEBUG)) || ((DIAG)) || ((DEV)) || ((INIT)); } ||
{
  # This works in Bash, so...
  0 () {
    ((QUIET)) ||
    >&2 echo "Invalid invocation of '0' as command! At $(caller)"
    false
  }
  1 () {
    ((QUIET)) ||
    >&2 echo "Invalid invocation of '1' as command! At $(caller)"
    true
  }
}
#else
#error unsupported shell LANG
#endif
#endif
#
# Id: user-script.standard.sh.h                  vim:set ft=bash sw=2 sts=2 et:
