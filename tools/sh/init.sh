#!/bin/sh

# This is for sourcing into a standalone or other env boot/init script (ie. CI)

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

test -n "$U_S" || U_S=$(pwd -P)

test -n "$sh_src_base" || sh_src_base=/src/sh/lib
test -n "$sh_util_base" || sh_util_base=/tools/sh

# Must be started from u-s project root or set before, or provide SCRIPTPATH
test -n "$scriptpath" || scriptpath="$U_S$sh_src_base"
test -n "$scriptname" || scriptname="$(basename "$0")"


SCRIPTPATH_=$scriptpath
SCRIPTPATH_=$SCRIPTPATH_:$U_S$sh_src_base
# FIXME: remove CI env
SCRIPTPATH_=$SCRIPTPATH_:$HOME/build/bvberkum/script-mpe/commands
SCRIPTPATH_=$SCRIPTPATH_:$HOME/build/bvberkum/script-mpe/contexts
SCRIPTPATH_=$SCRIPTPATH_:$HOME/build/bvberkum/script-mpe
SCRIPTPATH_=$SCRIPTPATH_:$HOME/build/bvberkum/user-conf/script
SCRIPTPATH_=$SCRIPTPATH_:$HOME/lib/sh

test -n "$SCRIPTPATH" && {

  SCRIPTPATH=$SCRIPTPATH_:$SCRIPTPATH
} || {

  SCRIPTPATH=$SCRIPTPATH_
}
unset SCRIPTPATH_
export SCRIPTPATH

test -n "$script_util" || script_util="$U_S$sh_util_base"


# Now include module loader with `lib_load`, setup by hand
. $scriptpath/lib.lib.sh
lib_lib_load && lib_lib_loaded=1 ||
  $LOG "error" "init.sh" "Failed at lib.lib $?" "" 1


# And conclude with logger setup but possibly do other script-util bootstraps.

test "$init_sh_libs" = "0" || {
  test -n "$init_sh_libs" -a "$init_sh_libs" != "1" ||
    init_sh_libs=sys\ os\ str\ script

  lib_load $init_sh_libs ||
    $LOG "error" "init.sh" "Failed at loading libs '$init_sh_libs' $?" "" 1


  test -n "$init_sh_boot" || init_sh_boot=0
  test -n "$init_sh_boot" && {
    test "$init_sh_boot" != "0" || init_sh_boot=null
    #test "$init_sh_boot" != "1" || init_sh_boot=stderr-console-logger
  }

  scripts_init $init_sh_boot ||
    $LOG "error" "init.sh" "Failed at bootstrap '$init_sh_boot' $?" "" 1

}

# Id: user-scripts/0.0.0-dev tools/sh/init.sh
