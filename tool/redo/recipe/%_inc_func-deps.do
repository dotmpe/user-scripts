
### Build .func-deps for .inc file

# List the names for commands that a function depends on (makes a direct call
# to).
#
# The basename of the target corresponds directly to one function name, defined
# as one per include file which are found through &inc-index (column 3).
#
# A build-ifchange dependency is made to the source file but not the index list
# or this source-do file, leaving that to the build setup.
#
# This uses dev setup of Oil-shell.

sh_mode strict build

assert_inc_dir REDO_STARTDIR


## Parameters

fun=$(basename -- "$1" .inc.func-deps)
dirn=$(dirname -- "${1:?}")

errs=$dirn/$fun.errors
self="do:$dirn/%%*.inc.func-deps($fun)"

# XXX: this uses a compiled include instead of inc so scan does only update
# when function typeset changes
src=.meta/src/inc/$fun.sh

# TODO: should resolve this fomr &inc-index, and use some setting for column
# nrs as well
funtab=${PROJECT_CACHE:?}/composure-index.list


## Recipe

mkdir -vp "$dirn" >&2

read -r fun opt inc pref <<< "$(grep "^$fun " "$funtab")"

build-ifchange "$src"

true "${OIL:=$HOME/project/oil}"
PYTHONPATH=$OIL:$PYTHONPATH $OIL/bin/oshc deps "$src" 2>| "$errs" >| "$3" &&
  test ! -s "$errs" && {
    test -s "$3" ||
        $LOG warn ":$self" "No output getting deps (ignored)" "$errs" 0

  } || {
    $LOG warn ":$self" "Errors getting deps (ignored)" "$errs" 0
  }
test -s "$errs" || rm "$errs"
build-stamp < "$3"
# Id: U-s:
