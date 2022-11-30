#!/usr/bin/env bash
# Was .cllct/src/components.list.do

set -euETo pipefail
shopt -s extdebug

redo-ifchange "$REDO_BASE/.meta/cache/stage.md5.git.scm" || return
(
  U_S=$REDO_BASE
  CWD=$REDO_BASE
    #shellcheck disable=2154
  . "${_ENV:="$REDO_BASE/tools/redo/env.sh"}" &&

  init_sh_libs="$init_sh_libs build-htd" \
    unit_mode=boot . "$REDO_BASE"/tools/sh/init.sh >&2

  scriptname="do:$REDO_PWD:$1"
  cd "$REDO_BASE" && build_components_id_path_map >"$REDO_PWD/$3"
)
redo-stamp <"$3"
