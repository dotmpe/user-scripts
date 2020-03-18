#!/usr/bin/env bash

status=return
true "${status:=return}"

run-d-lib-init()
{
  true "${RUNPATH:="$(run-d-find-path | tr ' ' ':')"}"
  test -n "$RUNPATH" || return
}

run()
{
  fnmatch "* -- *" " $* " && {
    local argv=
    while test $# -gt 0
    do
      argv=()
      while test $# -gt 0 -a "$1" != "--"
      do
        argv+=("$1")
        shift
      done
      shift
      run-scr "${argv[@]}" || return
    done
    return
  } || {
    local scriptcmd=
    for scriptcmd in "$@"
    do
      run-scr "$scriptcmd" || return
    done
  }
}

run-scr()
{
  # Execute shell requests on-host, no need to prefix with 'exec'
  case "$1" in sh | dash | posh | ksh | zsh | bash ) set -- exec "$@" ; esac

  local scriptcmd="$1"; shift

  # TODO: look for first run.d
  test -e "run.d/$scriptcmd.sh" && {

    . ./run.d/$scriptcmd.sh || $status $?

  } || {

    . "$HOME/.conf/dckr/run.d/$scriptcmd.sh" || $status $?
  }
}

run-d-find-path()
{
  while test -d $PWD/run.d
  do
    printf "$PWD/run.d"
    cd ..
    test -d $PWD/run.d && echo ' '
  done
}
