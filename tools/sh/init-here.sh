#!/bin/sh

# Alternative to init.sh (for project root dir), XXX: setup for new script subenv
# for this project. To get around the Sh no-source-arg limitation, instead of
# env keys instead this evaluates $@ after taking args. And it is still able to
# use $0 to get this scripts pathname and $PWD to add other dir.

# <script_util>/init-here.sh [SCRIPTPATH] [boot-script] [boot-libs] "$@"

test -n "$sh_src_base" || sh_src_base=/src/sh/lib
test -n "$sh_util_base" || sh_util_base=/tools/sh

scriptpath="$(dirname "$(dirname "$(dirname "$0")" )" )$sh_src_base"
script_util="$(dirname "$(dirname "$(dirname "$0")" )" )$sh_util_base"

test -n "$1" && {
  SCRIPTPATH=$1:$scriptpath
} || {
  SCRIPTPATH=$(pwd -P):$scriptpath
}


# Now include module loader with `lib_load` by hand
__load_mode=ext . $scriptpath/lib.lib.sh
lib_lib_load && lib_lib_loaded=1 || exit $?

# And conclude with logger setup but possibly do other script-util bootstraps.

test -n "$3" && init_sh_libs="$3" || init_sh_libs=sys\ os\ str\ script
lib_load $init_sh_libs

test -n "$2" && init_sh_boot="$2" || init_sh_boot=stderr-console-logger
script_init "$init_sh_boot"

shift 3

eval "$@"

# Id: script-mpe/0.0.4-dev tools/sh/init-here.sh
