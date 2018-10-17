#!/usr/bin/env bash
#
# Run all or specific unit-tests </doc/dev/ci>
#
# Usage:
#   ./unit.sh <function name>

set -o nounset
set -o pipefail
set -o errexit


test-bats-units()
{
  test -n "$*" || set -- test/unit/*.bats
  test "$1" != "test/unit/*.bats" || return 0
  # Run all tests as one suite/report run
  bats "$@"
}

# Groups

all()
{
  test-bats-units
}

"$@"
