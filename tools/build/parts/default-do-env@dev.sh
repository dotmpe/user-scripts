# Use ENV-BUILD as-is when given, or fall-back to default built-in method.
#test -e "${ENV_BUILD:?}" && {
#  . "$ENV_BUILD" || return
#} || {
#  default_do_env_default || return
#}

true "${ENV_BUILD_CACHE:=.meta/cache/redo-env.sh}"
#test -e "${ENV_BUILD_CACHE:?}" && {
#
#  . "$ENV_BUILD_CACHE" # || return
#} || {
  #default_do_env_default || return
  source "${U_S:?Required +U-s profile for @dev}/src/sh/lib/build.lib.sh" &&
  build_ env-build || return
#}
#
