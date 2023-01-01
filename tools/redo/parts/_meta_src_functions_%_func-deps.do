
sh_mode strict build

assert_inc_dir REDO_STARTDIR


fun=$(basename "$1" .func-deps)
dirn=$(dirname "${1:?}")
src=.meta/src/inc/$fun.sh
funtab=${PROJECT_CACHE:?}/composure-index.list
errs=$dirn/$fun.errors

mkdir -vp "$dirn" >&2

read -r fun opt inc pref <<< "$( grep "^$fun " "$funtab" )"

build-ifchange "$src"

true "${OIL:=$HOME/project/oil}"
PYTHONPATH=$OIL:$PYTHONPATH $OIL/bin/oshc deps "$inc" 2>| "$errs" >| "$3" &&
  test ! -s "$errs" && {
    test -s "$3" ||
        $LOG warn ":do:.meta/src/functions/%%*.func-deps" \
          "No output getting deps (ignored)" "$errs" 0

  } || {
        $LOG warn ":do:.meta/src/functions/%%*.func-deps" \
          "Errors getting deps (ignored)" "$errs" 0
  }
test -s "$errs" || rm "$errs"
build-stamp < "$3"
#
