#!/usr/bin/env bash
#
# Tools to maintain coding style standards </doc/dev/ci>
#
# Usage:
#   ./lint.sh <function name>

set -o pipefail
set -o errexit


test -n "$scriptpath" || exit 5
. $scriptpath/tools/sh/init.sh



lint-bats()
{
  test -n "$*" || set -- test/*.bats
  test "$1" != "test/*.bats" || return 0
  # Count flag to load, parse but dont step tests.
  bats -c "$@" >/dev/null
}


# Groups

check()
{
  echo "lint: check scripts..." >&2
  # TODO: lint markdown
  # TODO: lint sh-scripts
  # TODO: lint bash-scripts
  lint-bats "$@" && {
    git grep '\(XXX\|FIXME\|TODO\): .*\<no-commit\>' && return 1 || true
  } >&2
}

all()
{
  check
}

test -n "$1" || set -- all

"$@"
