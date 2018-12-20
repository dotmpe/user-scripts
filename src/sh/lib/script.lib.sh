#!/bin/sh

# Initial tools to help boot env for project/script

script_lib_load()
{
  test -n "$LOG" || return 102
  test -n "$sh_util_base" || sh_util_base=/tools/sh
  test -n "$script_util" || script_util=$(pwd -P)$sh_util_base
}

script_lib_init()
{
  test -n "$LOG" -a -x "$LOG" && script_log=$LOG || script_log=$PWD/tools/sh/log.sh
}

scripts_init()
{
  test $# -gt 0 || return
  while test $# -gt 0
  do
    script_init "$1" || return
    shift
  done
}

script_init()
{
  test -f "$1" && {

    $script_log info "script" "Bootstrapping from '$1'"
    . "$1"
  } || {
    test -e "$script_util/$1" && {

      $script_log info "script" "Bootstrapping script-util '$1'"
      . "$script_util/$1" || return

    } || {
      test -e "$script_util/boot/$1.sh" && {

        $script_log info "script" "Bootstrapping '$1'"
        . "$script_util/boot/$1.sh" || return

      } || {

        $script_log error "script" "Cannnot find script-init to boot '$1' at <$script_util>" "" 103 || return
      }
    }
  }
}
