#!/usr/bin/env bash
#
# System, integration and acceptance tests </doc/dev/ci>
#
# Usage:
#   ./lint.sh <function name>

set -o pipefail
set -o errexit


. ./tools/sh/init.sh


# Groups

check()
{
  print_yellow "" "spec: check scripts..." >&2
  bats -c test/spec/*.bats >/dev/null
}

all()
{
  print_yellow "" "spec: all scripts..." >&2
  bats test/spec/*.bats &&
  print_green "" "specs OK" >&2
}

test -n "$1" || set -- all

"$@"
