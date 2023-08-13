#!/usr/bin/env bash

! "${US_DEV:-false}" || {

  build-ifdone "${BUILD_CACHE:-${U_S:?}/.meta/cache}/us-profile.sh" &&
  . "$_"
}
#bool return ${REDO_DEBUG:-0}

sh_mode strict build

lib_require us-build log &&

# XXX:
##resolve fun sh-exception
##resolve fun sh-error
unset -f sh_{fun,error,exception}
. ./tools/sh/parts/sh-fun.sh

us_run tools/redo/default.do "$@"

# Id: U-s:default.do                                               ex:ft=bash:
