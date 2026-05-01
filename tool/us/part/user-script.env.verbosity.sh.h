# Copyright 2008-2026 B. van Berkum <dev@dotmpe.com>
#
# Distributed under terms of the MIT license.
#ifndef USER_SCRIPT_ENV_BASH
#define USER_SCRIPT_ENV_BASH
#if LANG == bash
: "${DEBUG:=0}"
: "${QUIET:=0}"
((QUIET)) && VERBOSE=0 || : "${VERBOSE:=0}"
#else
#error unsupported shell LANG
#endif
#endif
#
# Id: user-script.env.sh.h                       vim:set ft=bash sw=2 sts=2 et:
