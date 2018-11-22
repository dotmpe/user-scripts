#!/bin/sh

# scriptpath=<...> . <...>/init.sh

test -n "$sh_src_base" || sh_src_base=/src/sh

# Must be started from u-s project root or set before, or provide SCRIPTPATH
test -n "$scriptpath" || scriptpath="$(pwd -P)"

# if not provided, auto-setup env
# assuming execution starts in script dir (project root)
test -n "$SCRIPTPATH" && {

  SCRIPTPATH=$scriptpath$sh_src_base:$SCRIPTPATH
} || {

  SCRIPTPATH=$scriptpath$sh_src_base
}

test -n "$script_util" || export script_util=$scriptpath/tools/sh

# Now include script and run util_init to source other utils
__load_mode=ext . $scriptpath$sh_src_base/lib.lib.sh
lib_lib_load

. $script_util/logger.sh

# Id: script-mpe/0.0.4-dev tools/sh/init.sh
