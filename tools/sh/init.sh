#!/bin/sh

# This is for sourcing into a standalone or other env boot/init script (ie. CI)

# scriptpath=<...> . <script_util>/init.sh

# It requires a path to the basedir of the project to boot with. Containing:
# - scriptpath ?= $PWD
# - sh_src_base ?= /src/sh/lib
# - SCRIPTPATH %%= $scriptpath/$sh_src_base
# - script_util ?= $scriptpath/tools/sh

# It cannot determine the path to the init.sh, but instead setups like above.
# In addition, it takes these envs to select libs and boot script:

# init_sh_libs ?= sys os str
# init_sh_boot ?= stderr-console-logger


test -n "$sh_src_base" || sh_src_base=/src/sh/lib
test -n "$sh_util_base" || sh_util_base=/tools/sh

# Must be started from u-s project root or set before, or provide SCRIPTPATH
test -n "$scriptpath" || scriptpath="$(pwd -P)"

# if not provided, auto-setup env
# assuming execution starts in script dir (project root)
test -n "$SCRIPTPATH" && {

  SCRIPTPATH=$scriptpath$sh_src_base:$SCRIPTPATH
} || {

  SCRIPTPATH=$scriptpath$sh_src_base
}

test -n "$script_util" || script_util=$scriptpath$sh_util_base


# Cannot load/init without some provisionary logger setup
test -n "$LOG" || LOG=$script_util/log.sh
test -s "$LOG" || exit 102


# Now include module loader with `lib_load`, setup by hand
__load_mode=ext . $scriptpath/lib.lib.sh
lib_lib_load && lib_lib_loaded=1 ||
  $LOG "error" "init.sh" "Failed at lib.lib $?" "" 1


# And conclude with logger setup but possibly do other script-util bootstraps.

test "$init_sh_libs" = "0" || {
  test -n "$init_sh_libs" || init_sh_libs=sys\ os\ str\ script
  lib_load $init_sh_libs ||
    $LOG "error" "init.sh" "Failed at loading libs '$init_sh_libs' $?" "" 1
}

test -n "$init_sh_boot" || init_sh_boot=stderr-console-logger
test "$init_sh_boot" != "null" || {
  script_init "$init_sh_boot" ||
      $LOG "error" "init.sh" "Failed at bootstrap '$init_sh_boot' $?" "" 1
}


# Id: user-scripts/0.0.0-dev tools/sh/init.sh
