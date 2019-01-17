#!/usr/bin/env bash

ci_cleanup()
{
  exit=$? ; sync
  echo '------ Exited: '$exit  >&2
  # NOTE: BASH_LINENO is no use at travis, 'secure'
  #echo "At $BASH_COMMAND:$LINENO"
  test "$USER" = "travis" || return $exit
  sleep 5 # Allow for buffers to clear?
  return $exit
}

trap ci_cleanup EXIT
