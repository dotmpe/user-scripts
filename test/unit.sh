#!/usr/bin/env bash
#
# Component unit-tests </doc/dev/ci>
#
# Usage:
#   ./unit.sh <function name>

set -o pipefail
set -o errexit


test -n "$scriptpath" || exit 5
. $scriptpath/tools/sh/init.sh

lib_load build


# Groups

check()
{
  bats -c test/unit/*.bats >/dev/null
}

all()
{
  build_tests bats tap test/unit/*.bats | while read -r tap
  do
    build $tap
  done
}

test -n "$1" || set -- all

"$@"
