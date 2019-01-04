#!/bin/sh

# This is for sourcing into a standalone or other env boot/init script (ie. CI)


# NOTE: /bin/sh =/= Sh b/c BASH_ENV... sigh. Oh well, *that* works. Now this:
test -n "$BASHOPTS" || set +o nounset # die-bash-die


# U_S=<...> . <script_util>/init.sh

# It requires a path to the basedir of the project to boot with. Containing:
# - U_S ?= $PWD
# - sh_src_base ?= /src/sh/lib
# - SCRIPTPATH %%= $U_S/$sh_src_base
# - script_util ?= $U_S/tools/sh

# It cannot determine the path to the init.sh, but instead setups like above.
# In addition, it takes these envs to select libs and boot script:

# init_sh_libs ?= sys os str
# init_sh_boot ?= stderr-console-logger

test -n "$LOG" && LOG_ENV=1 || LOG_ENV=
test -n "$LOG" -a -x "$LOG" && INIT_LOG=$LOG || INIT_LOG=$PWD/tools/sh/log.sh

test -n "$U_S" || U_S=$(pwd -P)

test -n "$sh_src_base" || sh_src_base=/src/sh/lib
test -n "$sh_util_base" || sh_util_base=/tools/sh

# Must be started from u-s project root or set before, or provide SCRIPTPATH
test -n "$scriptpath" || scriptpath="$U_S$sh_src_base"
test -n "$scriptname" || scriptname="$(basename "$0")"
test -n "$script_util" || script_util="$U_S$sh_util_base"

# XXX: cleanup
#test -n "$script_env" || {
#  test -e "$PWD$sh_util_base/user-env.sh" &&
#    script_env=$PWD$sh_util_base/user-env.sh ||
#    script_env=$U_S$sh_util_base/user-env.sh
#}
#
#$INIT_LOG "info" "" "Loading user-script env..." "$script_env"
#. "$script_env"

# Now include module with `lib_load`
test -z "$DEBUG" || echo . $scriptpath/lib.lib.sh >&2
{
  . $scriptpath/lib.lib.sh || return
  lib_lib_load && lib_lib_loaded=1 || return
  lib_lib_init
} ||
  $INIT_LOG "error" "$scriptname:init.sh" "Failed at lib.lib $?" "" 1


# And conclude with logger setup but possibly do other script-util bootstraps.

test "$init_sh_libs" = "0" || {
  test -n "$init_sh_libs" -a "$init_sh_libs" != "1" ||
    init_sh_libs=sys\ os\ str\ script\ log\ shell

  $INIT_LOG "info" "$scriptname:sh:init" "Loading" "$init_sh_libs"
  test -n "$LOG" || LOG=$INIT_LOG

  lib_load $init_sh_libs ||
    $INIT_LOG "error" "$scriptname:init.sh" "Failed loading libs: $?" "$init_sh_libs" 1

  lib_init $init_sh_libs ||
    $INIT_LOG "error" "$scriptname:init.sh" "Failed init'ing libs: $?" "$init_sh_libs" 1

  test -n "$init_sh_boot" || init_sh_boot=1
  test -n "$init_sh_boot" && {
    test "$init_sh_boot" != "0" || init_sh_boot=null
    test "$init_sh_boot" != "1" || init_sh_boot=stderr-console-logger
  }

  test -z "$DEBUG" ||
    echo script_util=$script_util scripts_init $init_sh_boot >&2
  scripts_init $init_sh_boot ||
    $INIT_LOG "error" "$scriptname:init.sh" "Failed at bootstrap '$init_sh_boot'" $? 1
}

test -n "$LOG_ENV" && unset LOG_ENV INIT_LOG || unset LOG_ENV INIT_LOG LOG

# Id: user-scripts/0.0.0-dev tools/sh/init.sh
