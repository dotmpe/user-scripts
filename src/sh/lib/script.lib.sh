#!/bin/sh

# Initial tools to help boot env for project/script

script_lib_load()
{
  test -n "$LOG" || return 102
  test -n "$sh_tools" || sh_tools=$(pwd -P)/tools/sh
}

script_lib_init()
{
  test -n "$LOG" -a \( -x "$LOG" -o "$(type -t "$LOG")" = "function" \) \
    && script_log="$LOG" || script_log="$INIT_LOG"
}

script_lib_init_()
{
  set -- "$scriptname" "Delayed script-log init, check lib-init!"
  script_lib_init && $script_log warn "$@"
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
  test -n "$script_log" || script_lib_init_
  test -f "$1" && {

    $script_log info "script" "Bootstrapping from '$1'"
    . "$1" || return

  } || {

    sh_include_path=$U_S/tools/sh/boot sh_include "$1" || {

      $script_log error "script" "failed boot '$1' at <$sh_tools>" "" 103 || return
    }
  }
}
