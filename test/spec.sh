#!/usr/bin/env bash
#
# Run all or specific system, integration and acceptance tests </doc/dev/ci>
#
# Usage:
#   ./lint.sh <function name>

set -o nounset
set -o pipefail
set -o errexit


test-bats-specs()
{
  test -n "$*" || set -- test/*-spec.bats
  test "$1" != "test/*-spec.bats" || return 0
  # Run all tests as one suite/report run
  bats "$@"
}


# Groups

all()
{
  test-bats-specs
}

"$@"
