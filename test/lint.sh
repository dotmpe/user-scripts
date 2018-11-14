#!/usr/bin/env bash
#
# Tools to maintain coding style standards </doc/dev/ci>
#
# Usage:
#   ./lint.sh <function name>

set -o pipefail
set -o errexit


lint-bats()
{
  test -n "$*" || set -- test/*.bats
  test "$1" != "test/*.bats" || return 0
  # Count flag to dry-run (load, parse) tests.
  # Does not setup/step/teardown in anyway.
  bats -c "$@"
}

# Groups

check()
{
  # TODO: lint markdown
  # TODO: lint sh-scripts
  # TODO: lint bash-scripts
  lint-bats "$@" &&
  git grep '\(XXX\|FIXME\|TODO\): .*\<no-commit\>' && return 1 || true
}

all()
{
  check
}

default()
{
  all
}

test -n "$1" || set -- default

"$@"
