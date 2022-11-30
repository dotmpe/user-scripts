
sh_mode strict build

assert_inc_dir REDO_STARTDIR

mkdir -vp $(dirname "$1") >&2
fun=$(basename "$1" .func-deps)

read -r fun grp pref inc <<< "$(
    grep "^$fun " ${PROJECT_CACHE:?}/composure-index.list
  )"

build-ifchange .meta/src/inc/$fun.sh

errors=.meta/src/functions/$fun.errors
OIL=$HOME/project/oil
PYTHONPATH=$OIL:$PYTHONPATH $OIL/bin/oshc deps "$inc" 2>| "$errors" >| "$3" &&
  test ! -s "$errors" && {
    test -s "$3" ||
        $LOG warn ":do:.meta/src/functions/%%*.func-deps" \
          "No output getting deps (ignored)" "$errors" 0

  } || {
        $LOG warn ":do:.meta/src/functions/%%*.func-deps" \
          "Errors getting deps (ignored)" "$errors" 0
  }
test -s "$errors" || rm "$errors"
build-stamp < "$3"
#
