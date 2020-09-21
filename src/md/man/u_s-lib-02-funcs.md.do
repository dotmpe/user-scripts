#!/usr/bin/env bash
set -euo pipefail

true "${sh_libs_list:="$REDO_BASE/.cllct/src/sh-libs.list"}"
redo-ifchange $sh_libs_list
{
  echo "# See Also"
  sort -u "$sh_libs_list" |
  while read lib_id src
  do sh_lib_base="$REDO_BASE/.cllct/src/functions/$lib_id-lib"
    sh_lib_list="$sh_lib_base.func-list"
    { redo-ifchange $sh_lib_list && test -e $sh_lib_list
    } || { $LOG error "" "No $lib_id func-list"; continue; }
    printf "\nUser-Script:$lib_id(7)\n:"

    for func in $( sort -u $sh_lib_list )
    do echo "User-Script:$lib_id:$func(3sh)"
    done | sed 's/^/  - /g'
  done | sed 's/:  -/: -/g'
} >"$3"
redo-stamp <"$3"
test ! -e "$3" -o -s "$3" || rm "$3"
