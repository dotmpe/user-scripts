#!/bin/sh

git_version()
{
  git describe --always
}

u_s_version() #
{
  test $# -eq 0 || return 99
  test "$PWD" = "$U_S" || cd "$U_S"
  git_version
}
