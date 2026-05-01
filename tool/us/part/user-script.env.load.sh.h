# Copyright 2008-2026 B. van Berkum <dev@dotmpe.com>
#
# Distributed under terms of the MIT license.
#ifndef USER_SCRIPT_ENV_LOAD_BASH
#define USER_SCRIPT_ENV_LOAD_BASH
#if LANG == bash
[[ ${US_ENV_PARTS:+set} ]] &&
[[ ${US_ENV_INIT:+set} ]] &&
. <(echo "$US_ENV_INIT") || {
  >&2 echo "E$?: Expected User-Script env; definitions missing or source failure"
  exit 121
}
#else
#error unsupported shell LANG
#endif
#endif
#
# Id: user-script         vim:set ft=bash sw=2 sts=2 et:
