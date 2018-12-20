#!/bin/ash


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

  subcmd="$altpref$subcmd"
  type "$subcmd" 2>/dev/null >&2 && {
    eval ${prefid}subcmd=$subcmd
    return
  }

  $LOG error "ci:env" "No subcmd for '$2'"
  return 1
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
  export TEST_ENV package_build_tool

  local main_ret= base="$1" ; shift 1
  test -n "$base" || base="$(basename "$0" .sh)"

  test $# -gt 0 || set -- default
  req_usage_fail || return
  req_subcmd "$base-" "$1" || usage-fail "$base: $*"

  shift 1
  eval \$${prefid}subcmd "$@" || main_ret=$?
  unset ${prefid}subcmd prefid

  return $main_ret
}

main_test_() # Test-Cat [Cmd-Args...]
{
  export TEST_ENV package_build_tool

  local main_test_ret= testcat="$1" ; shift 1
  test -n "$testcat" || testcat=$(basename "$0" .sh)

  test $# -gt 0 || set -- all
  req_usage_fail || return
  req_subcmd "$testcat-" "$1" || usage-fail "test: $testcat: $*"

  shift 1
  eval \$${prefid}subcmd \"\$@\" || main_test_ret=$?
  unset ${prefid}subcmd prefid

  test -z "$main_test_ret" && print_green "" "OK" || {
    print_red "" "Not OK"
    return $main_test_ret
  }
}


#XXX: Travis errors? tools/sh/parts/env.sh
#set -o pipefail
#set -o nounset
#set -o errexit


. "${USER_ENV:=tools/sh/env.sh}"

# FIXME: make
: "${package_build_tool:=redo}"
: "${TEST_ENV:=$ci_util/env.sh}"

# NOTE: set default bash-profile (affects other Shell scripts)
#: "${BASH_ENV:=$USER_ENV}"
export USER_ENV BASH_ENV


case "$uname" in
  Darwin )  export gdate=gdate gsed=gsed ggrep=ggrep ;;
  Linux )   export gdate=date gsed=sed ggrep=grep ;;
esac


. ./tools/sh/parts/print-color.sh

. ./tools/ci/parts/util.sh


print_yellow "ci:env" "Starting: $0 '$*'" >&2
