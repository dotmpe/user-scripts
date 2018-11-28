#!/usr/bin/env bash


run()
{
  for scriptcmd in "$@"
  do
    run-scr "$scriptcmd"
  done
}

run-scr()
{
  # Execute shell requests on-host, no need to prefix with 'exec'
  case "$1" in sh | dash | posh | ksh | zsh | bash ) set -- exec "$@" ; esac

  local scriptcmd="$1"; shift

  # TODO: look for first run.d
  test -e "run.d/$scriptcmd.sh" && {

    . ./run.d/$scriptcmd.sh || exit $?

  } || {

    . "$HOME/.conf/dckr/run.d/$scriptcmd.sh" || exit $?
  }
}
