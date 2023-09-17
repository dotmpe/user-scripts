sh_mode dev

stderr echo "lib-load is a function"
. tools/sh/parts/lib_util.sh
. src/sh/lib/lib.lib.sh
sh_fun lib_load
lib_lib__load
lib_lib__init


stderr echo "~ that sources .lib.sh files"

test_libs=test/var/lib/sh
export SCRIPTPATH=$SCRIPTPATH:$test_libs
#export PATH=$PATH:$test_libs

lib_load example-us-empty


stderr echo "~ and tracks lib names, sources and status"

test -n "$lib_loaded"
test "$lib_loaded" = "example-us-empty"
test "$example_us_empty_lib_loaded" = "0"
test "$LIB_SRC" = "$test_libs/example-us-empty.lib.sh"

lib_load example-us-load-hook
test "$example_us_load_hook_lib_loaded" = "0"
test "$lib_loaded" = "example-us-empty example-us-load-hook"


#TODO "Lib load or init hook shall not call lib-load"


stderr echo "All libs load correctly"

libs=$(for scr in src/sh/lib/*.lib.sh; do basename "$scr" .lib.sh; done)
stderr echo "lib-require ${libs//$'\n'/ }"
lib_require $libs

#
