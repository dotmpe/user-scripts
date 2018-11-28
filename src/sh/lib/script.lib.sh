#!/bin/sh

script_lib_load()
{
  test -n "$LOG" || return 102
  test -n "$sh_util_base" || sh_util_base=/tools/sh
  test -n "$scriptpath" || scriptpath="$(pwd -P)"
}

script_init()
{
  test -n "$script_util" || script_util=$scriptpath$sh_util_base
  test -e "$1" && {

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

        $LOG error "script" "Cannnot find script-init '$1'" 103 || return
      }
    }
  }
}
