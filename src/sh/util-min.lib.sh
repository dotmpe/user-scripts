#!/bin/sh

set -e

note()
{
  test -z "$2" || error "Surplus arguments '$2'" 1
  test -n "$scriptname" &&
    echo "[$scriptname] $1" 1>&2 ||
    echo "$1" 1>&2
}

error()
{
  note "$1"
  test -z "$2" || exit $2
}

trueish()
{
  test -n "$1" || return 1
  case "$1" in
    on|true|yes|1)
      return 0;;
    * )
      return 1;;
  esac
}

type_exists()
{
  type $1 2> /dev/null 1> /dev/null || return $?
  return 0
}

dirname_()
{
  while test $1 -gt 0
    do
        set -- $(( $1 - 1 ))
        set -- "$1" "$(dirname "$2")"
    done
  echo "$2"
}

realdir_()
{
  set -- "$(dirname_ $1 "$2")"
  ( cd "$2" && pwd -P )
}

# Combined dirname/basename, to remove/replace .ext but retain entire path
pathname()
{
  echo "$(dirname "$1")/$(basename "$1" "$2")$3"
}

# Cumulative dirname, return the root directory of the path
basedir()
{
  while fnmatch "*/*" "$1"
  do
    set -- "$(dirname "$1")"
    test "$1" != "/" || break
  done
}

