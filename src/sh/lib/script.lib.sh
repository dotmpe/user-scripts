#!/bin/sh

# Initial tools to help boot env for project/script

script_lib_load()
{
  test -n "$LOG" || return 102
  test -n "$sh_util_base" || sh_util_base=/tools/sh
  test -n "$script_util" || script_util=$(pwd -P)$sh_util_base
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

    $LOG info "script" "Bootstrapping from '$1'"
    . "$1"
  } || {
    test -e "$script_util/$1" && {

      $LOG info "script" "Bootstrapping script-util '$1'"
      . "$script_util/$1" || return

    } || {
      test -e "$script_util/boot/$1.sh" && {

        $LOG info "script" "Bootstrapping '$1'"
        . "$script_util/boot/$1.sh" || return

      } || {

        $LOG error "script" "Cannnot find script-init '$1'" "" 103 || return
      }
    }
  }
}
