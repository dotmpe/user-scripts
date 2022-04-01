#!/usr/bin/env bash
set -euo pipefail

redo-ifchange "sh-libs.list"

redo_lib_id="$(basename -- "$1" -lib.func-list)" &&
case "$redo_lib_id" in
    default.functions-list ) exit 21 ;; # refuse to build non lib
    "*.func-list" ) exit 22 ;; # refuse to build non lib
    * ) ;; esac &&

# Transform target-name (redo_lib_id) to original file-paths
# Should really have just one path for shell-lib components
redo_paths="$(grep '^'"$redo_lib_id"'\>	' "sh-libs.list" | sed 's/^[^\t]*\t//g')" &&
test -n "$redo_paths" || {
  $LOG warn "$1" "No paths for '$redo_lib_id'"
  exit 0
}
mkdir -p "$(dirname "$1")"

# Redo if libs associated have changed.
# NOTE: would be nice to track function-source instead
redo-ifchange $( echo "$redo_paths" | sed 's#^\(\.\/\)\?#'"$REDO_BASE/"'#g' )

test ! -e "$1" -o -s "$1" || rm "$1"

# Pass filename to build routine
(
  U_S=$REDO_BASE
  CWD=$REDO_BASE
  . "${_ENV:="$REDO_BASE/tools/redo/env.sh"}" &&

  init_sh_libs="$init_sh_libs match src sys std package functions build-htd" &&
  util_mode=boot . $REDO_BASE/tools/sh/init.sh

  scriptname="do:$REDO_PWD:$1" && {
    test -n "$redo_lib_id" -a -n "$redo_paths" || {
      error "'$redo_lib_id' <$redo_paths>" 1 ;
    } ; } &&
  cd "$REDO_BASE" &&
  build_init && for path in $redo_paths
  do
    build_lib_func_list $redo_paths '\ \#.*\ sh:no-stat' | grep -v '^ *$'
  done >"$REDO_BASE/$REDO_PWD/$3"
  build_chatty && {
    cd "$REDO_PWD"
    echo "Listed $(wc -l "$3"|awk '{print $1}') shell functions from '$redo_lib_id' lib"  >&2
  } || true
)
redo-stamp <"$3"
test ! -e "$3" -o -s "$3" || rm "$3"
