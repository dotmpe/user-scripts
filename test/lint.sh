#!/usr/bin/env bash
#
# Run tools to maintain the coding style </doc/dev/ci>
#
# Usage:
#   ./lint.sh <function name>

set -o nounset
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
  lint-bats "$@"
}

all()
{
  check
}

"$@"
