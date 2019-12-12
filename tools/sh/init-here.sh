#!/bin/sh

# Alternative to init.sh (for project root dir), XXX: setup for new script subenv
# for this project. To get around the Sh no-source-arg limitation, instead of
# env keys instead this evaluates $@ after taking args. And it is still able to
# use $0 to get this scripts pathname and $PWD to add other dir.

# <sh_tools>/init-here.sh [SCRIPTPATH] [boot-script] [boot-libs] "$@"

test -n "$CWD" || CWD="$PWD"

# provisionary logger setup
test -n "$LOG" && LOG_ENV=1 || LOG_ENV=
test -n "${LOG:-}" -a -x "${LOG:-}" -o \
  "$(type -t "${LOG:-}" 2>/dev/null )" = "function" &&
  INIT_LOG=$LOG || INIT_LOG=$CWD/tools/sh/log.sh
# Sh-Sync: tools/sh/parts/env-init-log.sh

test -n "$sh_src_base" || sh_src_base=/src/sh/lib

case "$0" in -* ) ;; * ) # No-Sync
  U_S="$(dirname "$(dirname "$(dirname "$0")" )" )" # No-Sync
;; esac # No-Sync
test -n "$U_S" -a -d "$U_S" || . $PWD$sh_util_base/parts/env-0-u_s.sh
test -n "$U_S" -a -d "$U_S" || return

test -n "$scriptname" || scriptname="$(basename -- "$0")" # No-Sync
test -n "$sh_tools" || sh_tools="$U_S/tools/sh"

#test -n "$1" && {
#  SCRIPTPATH=$1:$scriptpath
#} || {
#  SCRIPTPATH=$(pwd -P):$scriptpath
#}

# Now include module with `lib_load`
test -z "$DEBUG" || echo . $U_S$sh_src_base/lib.lib.sh >&2
{
  . $U_S$sh_src_base/lib.lib.sh || return
  lib_lib_load && lib_lib_loaded=1 || return
  lib_lib_init
} ||
  $INIT_LOG "error" "$scriptname:init.sh" "Failed at lib.lib $?" "" 1

# And conclude with logger setup but possibly do other script-util bootstraps.

test -n "$3" && init_sh_libs="$3" || init_sh_libs=sys\ os\ str\ script

test "$init_sh_libs" = "0" || {
  lib_load $init_sh_libs && lib_init

  test -n "$2" && init_sh_boot="$2" || init_sh_boot=stderr-console-logger
  script_init "$init_sh_boot" || return
}

# XXX: test -n "$LOG_ENV" && unset LOG_ENV INIT_LOG || unset LOG_ENV INIT_LOG LOG

shift 3

eval "$@"

# Id: user-script/ tools/sh/init-here.sh
