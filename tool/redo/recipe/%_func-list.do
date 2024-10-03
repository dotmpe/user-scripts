
sh_mode strict build

redo-ifchange "${PROJECT_CACHE:?}/sh-libs.list" || return

lib_id="$(basename -- "$1" -lib.func-list)" &&
case "$lib_id" in
    default.functions-list ) exit 21 ;; # refuse to build non lib
    "*.func-list" ) exit 22 ;; # refuse to build non lib
    * ) ;; esac &&

# Transform target-name (lib_id) to original file-paths
# Should really have just one path for shell-lib components
{ lib_path="$(grep -m1 -E "( |/)$lib_id.lib.sh( |$)" ${PROJECT_CACHE:?}/sh-libs.list |
  cut -d' ' -f4)" && test -n "$lib_path" -a -e "$lib_path"
} || {
  $LOG warn "$1" "No paths for '$lib_id'"
  return 0
}

# Redo if libs associated have changed.
# NOTE: would be nice to track function-source instead
#shellcheck disable=SC2046,2001
redo-ifchange $(echo "$lib_path" | sed 's#^\(\.\/\)\?#'"$REDO_BASE/"'#g') ||
  return

test ! -e "$1" -o -s "$1" || rm "$1"

# Pass filename to build routine
(
  U_S=$REDO_BASE
  CWD=$REDO_BASE

  init_sh_libs="os str log match src sys std package functions build-htd" &&
  util_mode=boot . "$REDO_BASE"/tools/sh/init.sh || return

  scriptname="do:$REDO_PWD:$1" && {
    test -n "$lib_id" -a -n "$lib_path" || {
      error "'$lib_id' <$lib_path>" 1 ;
    } ; } &&
  cd "$REDO_BASE" &&
  build_init && for path in $lib_path
  do
    #shellcheck disable=2086
    build_lib_func_list $lib_path '\ \#.*\ sh:no-stat' | grep -v '^ *$'
  done >"$REDO_BASE/$REDO_PWD/$3"
)
redo-stamp <"$3"
test ! -e "$3" -o -s "$3" || rm "$3"
