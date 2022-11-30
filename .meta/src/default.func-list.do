#!/usr/bin/env bash
set -euo pipefail

redo-ifchange "../cache/sh-libs.list" || return

redo_lib_id="$(basename -- "$1" -lib.func-list)" &&
case "$redo_lib_id" in
    default.functions-list ) exit 21 ;; # refuse to build non lib
    "*.func-list" ) exit 22 ;; # refuse to build non lib
    * ) ;; esac &&

# Transform target-name (redo_lib_id) to original file-paths
# Should really have just one path for shell-lib components
{ redo_lib_path="$(grep "/\?$redo_lib_id.lib.sh" ../cache/sh-libs.list | cut -d' ' -f4)" &&
  test -n "$redo_lib_path"
} || {
  $LOG warn "$1" "No paths for '$redo_lib_id'"
  exit 0
}
mkdir -p "$(dirname "$1")"

# Redo if libs associated have changed.
# NOTE: would be nice to track function-source instead
#shellcheck disable=SC2046,2001
redo-ifchange $(echo "$redo_lib_path" | sed 's#^\(\.\/\)\?#'"$REDO_BASE/"'#g')

test ! -e "$1" -o -s "$1" || rm "$1"

# Pass filename to build routine
(
  U_S=$REDO_BASE
  CWD=$REDO_BASE

  init_sh_libs="os str log match src sys std package functions build-htd" &&
  util_mode=boot . "$REDO_BASE"/tools/sh/init.sh

  scriptname="do:$REDO_PWD:$1" && {
    test -n "$redo_lib_id" -a -n "$redo_lib_path" || {
      error "'$redo_lib_id' <$redo_lib_path>" 1 ;
    } ; } &&
  cd "$REDO_BASE" &&
  build_init && for path in $redo_lib_path
  do
    #shellcheck disable=2086
    build_lib_func_list $redo_lib_path '\ \#.*\ sh:no-stat' | grep -v '^ *$'
  done >"$REDO_BASE/$REDO_PWD/$3"
)
redo-stamp <"$3"
test ! -e "$3" -o -s "$3" || rm "$3"
