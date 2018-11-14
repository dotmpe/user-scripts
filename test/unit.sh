#!/usr/bin/env bash
#
# Component unit-tests </doc/dev/ci>
#
# Usage:
#   ./unit.sh <function name>

set -o pipefail
set -o errexit


test-bats-units()
{
  test -n "$*" || set -- test/unit/*.bats
  test "$1" != "test/unit/*.bats" || return 0
  # Run all tests as one suite/report run
  bats "$@"
}

default_test_run()
{
  local test_fmt=$1 report_fmt=$2; shift 2

  for x in "$@"
    do
      test="test/$(basename $x .$test_fmt).$report_fmt"
    done
}

# Groups

check()
{
  true
}

all()
{
  test-bats-units
}

default()
{
  all
}

test -n "$1" || set -- default

"$@"
