#!/usr/bin/env bash
: "${DEBUG:=0}"
: "${QUIET:=0}"
((QUIET)) && VERBOSE=0 || : "${VERBOSE:=0}"
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
[[ ${US_ENV_PARTS:+set} ]] &&
[[ ${US_ENV_INIT:+set} ]] &&
. <(echo "$US_ENV_INIT") || {
  >&2 echo "E$?: Expected User-Script env; definitions missing or source failure"
  exit 121
}
