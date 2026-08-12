# Copyright 2008-2026 B. van Berkum <dev@dotmpe.com>
#
# Distributed under terms of the MIT license.
#ifndef USER_SCRIPT_BUILD_ENV_LOCAL_BASH
#define USER_SCRIPT_BUILD_ENV_LOCAL_BASH
#ifdef US_CONFIGURE
US_ENV_SOURCE($EWD/$METADIR/config/us-build-config.bash)
#config_assert $METADIR/config/us-build-config.bash <<EOM
#XXX
#EOM
# declare -gA \
# us_build_env=(
#   [env]=""
#   [build-env]=""
# )
# declare -gA \
# us_build_targets=(
#   [env]=
# )
#else
#endif
# See EWD part for persistence of US_{BUILD_EXT,ENV_{LOCAL,BUILD}}
# 
: "${US_ENV_LOCAL:=./.local-env.bash}"
: "${US_ENV_BUILD:=./.build-env.bash}"
: "${US_BUILD_EXT:=.build}"
if [[ -s "$US_ENV_LOCAL${US_BUILD_EXT}" ]]
then
  >&2 echo us-build "${US_ENV_LOCAL}${US_BUILD_EXT}" &&
  us-build "${US_ENV_LOCAL}${US_BUILD_EXT}" &&
  . "$US_ENV_LOCAL" ||
    failerr "E$? processing local env build <$_>" $?
    # $LOG error : "E$? processing local env build" "$_" $? || return
else
  failerr "No source for local env build <${US_ENV_LOCAL-(unset)}${US_BUILD_EXT-(unset)}>" 120
  # $LOG alert : "No source for local env build" "" 120 || return
fi
if [[ -s "$US_ENV_BUILD${US_BUILD_EXT}" ]]
then
  >&2 echo us-build "${US_ENV_BUILD}${US_BUILD_EXT}" &&
  us-build "${US_ENV_BUILD}${US_BUILD_EXT}" &&
  . "$US_ENV_BUILD" ||
    failerr "E$? processing local build env <$_>" $?
    # $LOG error : "E$? processing local build env" "$_" $? || return
else
  failerr "No source for local build env build <${US_ENV_BUILD(unset)}${US_BUILD_EXT-(unset)}>" 120
  # $LOG alert : "No source for local build env" "" 120 || return
fi
#endif
# Id: user-script.env.local.bash                 vim:set ft=bash sw=2 sts=2 et:
