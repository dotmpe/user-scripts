#!/usr/bin/env bash

#! "${US_DEV:-false}" || {
#
#  build-ifdone "${BUILD_CACHE:-${U_S:?}/.meta/cache}/us-profile.sh" &&
#  . "$_"
#}
#bool return ${REDO_DEBUG:-0}

sh_mode strict build

lib_require us-build log &&
lib_init us-build

#resolve fun sh-exception
#resolve fun sh-error
#XXX: unset -f sh_{fun,error,exception}
. ./tools/sh/parts/sh-fun.sh

: "${_E_GAE:=193}" # Generic Argument Error

: "${_E_ok:=195}" # Explicit OK (finished, continue)
: "${_E_next:=196}" # Try next alternative (unfinished or partial)
#: "${_E_break:=197}" # success; last step, finish batch, ie. stop loop now and wrap-up

us_run tools/redo/default.do "$@"

# Id: U-s:default.do                                               ex:ft=bash:
