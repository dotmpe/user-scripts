#!/usr/bin/env bash
set -euo pipefail

sh_files="$REDO_BASE/.meta/cache/sh-files.list"
# $REDO_PWD/sh-files.list

redo-ifchange "$sh_files"
(
  U_S=$REDO_BASE CWD=$REDO_BASE
  . "${_ENV:="$REDO_BASE/tools/redo/env.sh"}" &&

  init_sh_libs="$init_sh_libs build-htd functions" \
    util_mode=boot . $REDO_BASE/tools/sh/init.sh

  scriptname="do:$REDO_PWD:$1"
  cd "$REDO_BASE" && functions_execs < $sh_files 2>/dev/null \
      | sort -u >"$REDO_PWD/$3"
)
redo-stamp <"$3"