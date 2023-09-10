#!/usr/bin/env bash

! "${US_DEV:-false}" || {

  build-ifdone "${BUILD_CACHE:-${U_S:?}/.meta/cache}/us-profile.sh" &&
  . "$_"
}
#bool return ${REDO_DEBUG:-0}

lk=u-s:default.do[$$]
export UC_LOG_BASE=$lk

sh_mode build strict

lib_require str script-mpe us-build log ||
  stderr echo E$?:lib-require

us_preproc_vardefs[":"]=u-s
us_preproc_vardefs["u-s"]="$U_S"

lib_init us-build

##resolve fun sh-exception
##resolve fun sh-error
#XXX: unset -f sh_{fun,error,exception}
. ./tools/sh/parts/sh-fun.sh
: "${_E_GAE:=193}" # Generic Argument Error

: "${_E_ok:=195}" # Explicit OK (finished step, continue batch)
: "${_E_next:=196}" # Try next (unfinished: missing alt or partial batch)
#: "${_E_break:=197}" # success; last step, finish batch, ie. stop loop now and wrap-up
# Failure, but check keep-going


us_build_trgt_ext=.do \
us_main tools/redo/default.do "$@"

# Id: U-s:default.do                                               ex:ft=bash:
