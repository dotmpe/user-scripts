#!/bin/ash
# XXX: usr/bin/env bash

#set -o nounset Travis errrors?
set -o pipefail
set -o nounset
set -o errexit

# NOTE: set default bash-profile (affects other Shell scripts)
#test -n "${BASH_ENV:-}" ||
. "${BASH_ENV:=tools/sh/env.sh}"


fnmatch() { case "$2" in $1 ) return;; * ) return 1;; esac; }

assert_nonzero()
{
  test $# -gt 0 && test -n "$1"
}

# XXX: Map to namespace to avoid overlap with builtin names
req_subcmd() # Alt-Prefix [Arg]
{
  test $# -gt 0 -a $# -lt 3 || return
  local dflt= altpref="$1" subcmd="$2"

  prefid="$(printf -- "$altpref" | tr -sc 'A-Za-z0-9_' '_')"

  type "$subcmd" 2>/dev/null >&2 && {
    eval ${prefid}subcmd=$subcmd
    return
  }
  test -n "$altpref" || return

  subcmd="$altpref$1"
  type "$subcmd" 2>/dev/null >&2 && {
    eval ${prefid}subcmd=$subcmd
    return
  }
  return 1
}

case "$uname" in
  Darwin )  export gdate=gdate gsed=gsed ggrep=ggrep ;;
  Linux )   export gdate=date gsed=sed ggrep=grep ;;
esac

c_normal="$(tput sgr0)"
c_black="$(tput setaf 0)"
c_red="$(tput setaf 1)"
c_green="$(tput setaf 2)"
c_yellow="$(tput setaf 3)"
#c_blue="$(tput setaf 4)"
#c_purple="$(tput setaf 5)" # magenta
c_bold="$(tput bold)"
c_default="$(tput setaf 7)"
print_red()
{
  test -n "$1" || set -- "$scriptname" "$2"
  printf "%s[%s%s%s] %s%s%s\n" "$c_red" "$c_default" "$1" "$c_red" "$c_default" "$2" "$c_normal"
}
print_yellow()
{
  test -n "$1" || set -- "$scriptname" "$2"
  printf "%s[%s%s%s] %s%s%s\n" "$c_yellow" "$c_default" "$1" "$c_yellow" "$c_default" "$2" "$c_normal"
}
print_green()
{
  test -n "$1" || set -- "$scriptname" "$2"
  printf "%s[%s%s%s] %s%s%s\n" "$c_green" "$c_default" "$1" "$c_green" "$c_default" "$2" "$c_normal"
}

req_usage_fail()
{
  type "usage-fail" 2>/dev/null >&2 || {
    $LOG "error" "" "Expected usage-fail in $0" "" 3
    return 3
  }
}

main_() # [Base] [Cmd-Args...]
{
  local main_ret= base="$1" ; shift 1
  test -n "$base" || base="$(basename "$0" .sh)"

  test $# -gt 0 || set -- default
  req_usage_fail || return
  req_subcmd "$base-" "$1" || usage-fail "$@"

  shift 1
  eval \$${prefid}subcmd "$@" || main_ret=$?
  unset subcmd ${prefid}subcmd prefid

  return $main_ret
}

main_test_() # Test-Cat [Cmd-Args...]
{
  local ret= testcat="$1" ; shift 1
  local main_test_ret=

  test $# -gt 0 || set -- all
  req_usage_fail || return
  req_subcmd "test-$testcat-" "$1" || usage-fail "$@"

  shift 1
  eval \$${prefid}subcmd "$@" || main_test_ret=$?
  unset subcmd ${prefid}subcmd prefid

  test -z "$main_test_ret" && print_green "" "OK" || {
    print_red "" "Not OK"
    return $main_test_ret
  }
}

print_yellow "ci:env" "Starting: $0 '$*'" >&2
