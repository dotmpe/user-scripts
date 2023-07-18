
### Build .func-deps for shell function library file

# List the names for commands used in a shell script.

# XXX: not sure if e.g time and sudo would be listed, need to check with setup


sh_mode strict dev

assert_base_dir


## Parameters

funcname=$(basename -- "$1" .func-deps)
dirn=$(dirname "$1")
stderr=$dirn/$funcname.stderr
lib_id=$(basename -- "$dirn" -lib)
dirn=$(dirname "$dirn")
self="do:$dirn:%%*.func-deps($lib_id:$funcname)"

case "$lib_id" in
  default.func-deps ) exit 21 ;; # refuse to build non lib
  "*.func-deps" ) exit 22 ;; # refuse to build non lib
esac

sh_libs=${PROJECT_CACHE:?}/sh-libs.list


## Recipe

# Shell function libraries have unique file names: <id>.lib.sh
# so can easily pick location from list
redo-ifchange "$sh_libs"
{ lib_path="$(grep -m1 "\( \|/\)$lib_id\.lib\.sh " "$sh_libs" | cut -d' ' -f4)" &&
  test -n "$lib_path" -a -e "$lib_path"
} ||
  $LOG error ":$self" "No such lib_path '$lib_path'" "" 1 || return

$LOG debug :$self "Starting scan..."
mkdir -vp "$dirn/$lib_id-lib"

# XXX: "$dirn/$lib_id"-lib.func-list
redo-ifchange "${lib_path:?}" || return

U_S=$BUILD_BASE
CWD=$BUILD_BASE
scriptname="$self"

init_sh_libs="os str log match src std function functions build"
. "${U_S:?}"/tools/sh/init.sh

# XXX: cleanup, still depends on ~/bin
SCRIPTPATH=${SCRIPTPATH:?}:$HOME/bin
lib_require package os-htd build-htd

r=

build_lib_func_deps_list "$funcname" "$lib_path" >| "$3" 2>| "$stderr" || r=$?
test -z "${r-}" || {
  $LOG error ":$self" "Failed ($r), see" "$stderr"

  env | grep -i redo >&2
  exit $r
}
$LOG info :$self "Finished scan" "E$r"

# FIXME: lots of OSHC errors in scripts, track in stderr for now
test ! -e "$stderr" -o -s "$stderr" || rm "$stderr"
test ! -e "$stderr" || {
  build_chatty && {
    build_chatty 4 && cat "$stderr" >&2
    $LOG "warn" ":$self" "Errors during processing" "$stderr"
  }
}

redo-stamp <"$3"
test -s "$3" || rm "$3"
