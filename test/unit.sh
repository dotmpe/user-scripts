#!/usr/bin/env bash
#
# Component unit-tests </doc/dev/ci>
#
# Usage:
#   ./unit.sh <function name>

set -o pipefail
set -o errexit


. ./tools/sh/init.sh

lib_load build


# Groups

check()
{
  print_yellow "" "unit: check scripts..." >&2
  bats -c test/unit/*.bats >/dev/null
}

all()
{
  print_yellow "" "unit: all scripts..." >&2
  build_tests bats tap test/unit/*.bats | while read -r tap
  do
    build $tap || true
  done

  grep -q '^NOT OK\ ' test/unit/*.tap && false || true
}

test -n "$1" || set -- all

"$@"
