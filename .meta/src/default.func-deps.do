#!/usr/bin/env bash
set -euo pipefail

funcname="$(basename -- "$1" .func-deps)"
lib_id="$(basename -- "$(dirname "$1")" -lib)"
case "$lib_id" in
    default.func-deps ) exit 21 ;; # refuse to build non lib
    "*.func-deps" ) exit 22 ;; # refuse to build non lib
    * ) ;; esac

redo-ifchange "$REDO_BASE/.meta/src/default.func-deps.do"

redo-ifchange "sh-libs.list"

# Transform target-name (lib_id) to original file-paths
# Should really have just one path for shell-lib components
path="$(grep '^'"$lib_id"'\>	' "sh-libs.list" | sed 's/^[^\t]*\t//g')"

test -n "$path" -a -e "$REDO_BASE/$path" || { echo "No such path '$path'" >&2; exit 1; }
mkdir -p "$(dirname "$1")"

redo-ifchange functions/"$lib_id"-lib.func-list "$REDO_BASE/${path:?}"

test ! -e "$1" -o -s "$1" || rm "$1"

#shellcheck disable=2154

U_S=$REDO_BASE CWD=$REDO_BASE . "${_ENV:="$REDO_BASE/tools/redo/env.sh"}" &&

CWD=$REDO_BASE \
init_sh_libs="$init_sh_libs match src std function functions" \
U_S="$REDO_BASE" . "$REDO_BASE"/tools/sh/init.sh

# XXX: cleanup, still depends on ~/bin
SCRIPTPATH=$SCRIPTPATH:$HOME/bin
lib_require package os-htd build-htd

r=

scriptname="do:$REDO_PWD:$1" && {
  test -n "$lib_id" -a -n "$funcname" -a -n "$path" || {
    error "'$lib_id:$funcname' <$path>" 1
  } ; } &&
mkdir -p "functions/$lib_id-lib/" &&
cd "$REDO_BASE" &&
build_lib_func_deps_list "$funcname" "$path" >"$REDO_PWD/$3" \
  2>"$REDO_PWD/$1.stderr" || r=$?

test -z "${r-}" || {
  $LOG error "" "Failed ($r), see" "$1.stderr"
  exit $r
}

cd "$REDO_BASE/$REDO_PWD"
# FIXME: lots of OSHC errors in scripts, track in stderr for now
test ! -e "$1.stderr" -o -s "$1.stderr" || rm "$1.stderr"
test ! -e "$1.stderr" || {
  build_chatty && {
    build_chatty 4 && cat "$1.stderr" >&2
    $LOG "warn" "" "Errors during processing" "$1.stderr"
  }
}

redo-stamp <"$3"
test ! -e "$3" -o -s "$3" || rm "$3"
