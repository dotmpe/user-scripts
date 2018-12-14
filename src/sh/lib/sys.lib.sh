#!/bin/sh

# Sys: dealing with vars, functions, env.

sys_lib_load()
{
  test -n "$LOG" || return 102
  test -n "$uname" || uname="$(uname -s)"
  test -n "$hostname" || hostname="$(hostname -s | tr 'A-Z' 'a-z')"
}


# Error unless non-empty and true-ish value
trueish() # Str
{
  test -n "$1" || return 1
  case "$1" in [Oo]n|[Tt]rue|[Yyj]|[Yy]es|1) return 0;;
    * ) return 1;;
  esac
}

# Error unless non-empty and falseish
falseish()
{
  test -n "$1" || return 1
  case "$1" in
    [Oo]ff|[Ff]alse|[Nn]|[Nn]o|0)
      return 0;;
    * )
      return 1;;
  esac
}

func_exists()
{
  type $1 2> /dev/null 1> /dev/null || return $?
  return 0
}


