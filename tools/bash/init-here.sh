#!/usr/bin/env bash

# Alternative to init.sh (for project root dir), XXX: setup for new script subenv
# for this project. To get around the Sh no-source-arg limitation, instead of
# env keys instead this evaluates $@ after taking args. And it is still able to
# use $0 to get this scripts pathname and $PWD to add other dir.

# tools/bash/init-here.sh [SCRIPTPATH] [boot-script] [boot-libs] "$@"

# provisionary logger setup
test -n "${LOG:-}" && LOG_ENV=1 || LOG_ENV=
test -n "${LOG:-}" -a -x "${LOG:-}" -o \
  "$(type -t "${LOG:-}" 2>/dev/null )" = "function" &&
  INIT_LOG=$LOG || INIT_LOG=$CWD/tools/sh/log.sh
# Sh-Sync: tools/sh/parts/env-init-log.sh

test -n "$U_S" || U_S="$(dirname "$(dirname "$(dirname "$0")" )" )"

: "${sh_src_base:="/src/sh/lib"}"

: "${scriptpath:="$U_S$sh_src_base"}"
: "${scriptname:="$(basename -- "$0")"}"
: "${sh_tools:="$U_S/tools/sh"}"

test -n "${1:-}" && {
  SCRIPTPATH=$1:$scriptpath
} || {
  SCRIPTPATH=$(pwd -P):$scriptpath
}

# Now include module with `lib_load`
test -z "$DEBUG" || echo . $scriptpath/lib.lib.sh >&2
{
  . $scriptpath/lib.lib.sh || return
  lib_lib_load && lib_lib_loaded=0 || return
  lib_lib_init
} ||
  $INIT_LOG "error" "$scriptname:init.sh" "Failed at lib.lib $?" "" 1

# And conclude with logger setup but possibly do other script-util bootstraps.

test -n "${3:-}" && init_sh_libs="$3" || init_sh_libs=sys\ os\ str\ script

test "$init_sh_libs" = "0" || {
  lib_load $init_sh_libs

  test -n "${2:-}" && init_sh_boot="$2" || init_sh_boot=null # FIXME: stderr-console-logger
  script_init "$init_sh_boot"
}

# XXX: test -n "$LOG_ENV" && unset LOG_ENV INIT_LOG || unset LOG_ENV INIT_LOG LOG

shift 3

eval "$@"

# Id: user-script/ tools/sh/init-here.sh
