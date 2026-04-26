## Copyright 2008-2026 B. van Berkum <dev@dotmpe.com>
##
## Distributed under terms of the MIT license.
#ifndef USER_SCRIPT_HOST_PROFILE_SH_H
#define USER_SCRIPT_HOST_PROFILE_SH_H
#include <user-script.env.sh.h>
# FIXME: configure scripts based on US installation (and build definitions)
#  TODO: include <user-script.host-profile.init.bash
[[ ${US_ENV_PARTS:+set} ]] &&
[[ ${US_ENV_INIT:+set} ]] &&
eval "$US_ENV_INIT" || {
  >&2 echo "Expected User-Script env"
  exit 121
}
#endif
#
# Id: user-script.host-profile.bash.h            vim:set ft=bash sw=2 sts=2 et:
