#!/usr/bin/env bash

# TODO: see U-S:tools/sh/build.sh, HT:bg.sh

echo_lines () # [ - | FILE ]
{
  test -e "${1-}" -o "${1-}" = "-" || return
  local in
  test $# -eq 1 && in=$1 || in=1
  wc -l "$in" | { read lines _; echo "$in: $lines lines"; }
}

build_dbgcmd () # Cmd-Line...
{
  test ${DEBUG-0} -eq 0 || echo "$*" >&2
  eval "$@"
}

# Boot next command on cmd-line
build_sub () # Cmd-Part Cmd-Args...
{
  local build_sub build_sub_cmd= build_sub_cmd_ret=
  build_sub=$1
  build_sub_cmd="${1//[^A-Za-z0-9_]/_}"
  shift

  # Defer to part script
  # TODO: can we defer to background, and notify or block for redo calls?
  test $DEBUG -eq 0 || echo "$build_sub_cmd '$*'" >&2
  $build_sub_cmd "$@" || build_sub_cmd_ret=$?

  return $build_sub_cmd_ret
}

# Boot next command on cmd-line, include any parts first.
build_deps_subs () # Dep-Parts... -- Cmd-Parts... -- Cmd-Args...
{
  local deps=str-id\  cmds=

  while test "$1" != '--'
  do deps="$deps$1 ";shift
  done; shift

  while test "$1" != '--'
  do cmds="$cmds$1 ";shift
  done; shift

  test $DEBUG -eq 0 || echo "sh_include '$deps $cmds'" >&2
  sh_include $deps $cmds || return

  # Don't include '--' after last command-name
  set -- $cmds -- "$@"; test $2 != -- || { shift 2; set -- $cmds "$@"; }
  build_sub "$@"
}

build_htdocs_main () # Dep-Parts... -- Cmd-Parts.. -- Cmd-Args..
{
  true "${DEBUG:=0}"
  set -euo pipefail
  cd "$CWD"

  # Initialize sh_include
  . $CWD/tools/sh/init-include.sh
  sh_include_path_langs="build ci sh main"

  # Defer to builder(s)
  test $DEBUG -eq 0 || echo "build_sub $*'" >&2
  local h=
  fnmatch "* -- * -- *" " $* " && h=build_deps_subs || h=build_sub
  $h "$@"
}

build_htdocs_main "$@"

# Id: U-S:                                                         ex:ft=bash:
